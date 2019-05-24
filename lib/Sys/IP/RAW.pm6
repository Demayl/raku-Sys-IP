unit module Sys::IP::RAW;
use NativeCall;
use Sys::IP::Routes; # get_routes

enum AddrInfo-Family (
    AF_UNSPEC => 0;
    AF_PACKET => 17; # Packat family
    AF_INET => 2;
    AF_INET6 => 10;
);

enum IFACE_STAT ( # from if.h; man netdevice
    IFF_UP          => 1 +< 0; # Interface is up
    IFF_BROADCAST   => 1 +< 1;
    IFF_LOOPBACK    => 1 +< 3;
    IFF_POINTOPOINT => 1 +< 4;
    IFF_RUNNING     => 1 +< 6;
    IFF_MULTICAST   => 1 +< 12;
);

constant \INET_ADDRSTRLEN = 16; # 15 + \0
constant \INET6_ADDRSTRLEN = 46;


# struct ifaddrs {
#     struct ifaddrs ifa_next; / Next item in list */
#     char ifa_name; / Name of interface */
#     unsigned int ifa_flags; / Flags from SIOCGIFFLAGS /
#     struct sockaddr ifa_addr; / Address of interface */
#     struct sockaddr ifa_netmask; / Netmask of interface */
#     union {
#         struct sockaddr *ifu_broadaddr;
#         / Broadcast address of interface /
#         struct sockaddr *ifu_dstaddr;
#         / Point-to-point destination address /
#     } ifa_ifu;
#     #define ifa_broadaddr ifa_ifu.ifu_broadaddr
#     #define ifa_dstaddr ifa_ifu.ifu_dstaddr
#     void ifa_data; / Address-specific data */
# };


class SockAddr is repr('CStruct') {
    has int32 $.sa_family;
    has CArray[uint8] $.sa_data is rw;
}

#           struct sockaddr_ll {
#               unsigned short sll_family;   /* Always AF_PACKET */
#               unsigned short sll_protocol; /* Physical-layer protocol */
#               int            sll_ifindex;  /* Interface number */
#               unsigned short sll_hatype;   /* ARP hardware type */
#               unsigned char  sll_pkttype;  /* Packet type */
#               unsigned char  sll_halen;    /* Length of address */
#               unsigned char  sll_addr[8];  /* Physical-layer address */
#           };

class SockAddrLL is repr('CStruct') {
    has uint16 $.sll_family;
    has uint16 $.sll_protocol;
    has int     $.sll_ifindex;
    has uint16 $.sll_hatype;
    has uint8 $.sll_pkttype;
    has uint8 $.sll_halen;
    has Str $.sll_addr;

    method address { # TODO
        $!sll_halen;
    }

}

# inet_ntop - convert IPv4 and IPv6 addresses from binary to text form
sub inet_ntop(int32, Pointer, Blob, int32 --> Str) is native {}

sub freeifaddrs(Pointer) is native { * };
sub getifaddrs(Pointer is rw) returns int32 is native { * }
# When getifaddrs() fails, errno can be set to one of the following:
# [ENOMEM]    No memory available for the ifaddrs linked list.
# [ENXIO]     No interfaces exist.


class SockAddr-in is repr('CStruct') { # TODO ipv6
    has int16 $.sin_family;
    has uint16 $.sin_port;
    has uint32 $.sin_addr;

    method address {
        my $buf = buf8.allocate(INET_ADDRSTRLEN);
        inet_ntop(AF_INET, Pointer.new(nativecast(Pointer,self)+4),
        $buf, INET_ADDRSTRLEN)
    }
}


class SockAddr-in6 is repr('CStruct') {
    has uint16 $.sin6_family;
    has uint16 $.sin6_port;
    has uint32 $.sin6_flowinfo;
    has uint64 $.sin6_addr0;
    has uint64 $.sin6_addr1;
    has uint32 $.sin6_scope_id;

    method address {
        my $buf = buf8.allocate(INET6_ADDRSTRLEN);
        inet_ntop(AF_INET6, Pointer.new(nativecast(Pointer,self)+8),
            $buf, INET6_ADDRSTRLEN)
    }
}

class IfAddrs is repr('CStruct') is export { # TODO test 4 leaks
    has IfAddrs  $.ifa_next is rw; # referenced
    has Str      $.ifa_name;
    has uint     $.ifa_flags;
    has SockAddr $.ifa_addr is rw;
    has SockAddr $.ifa_netmask is rw;
    has SockAddr $.ifa_ifu is rw; # CUnion, but has 2 same type-size structs
    has Pointer  $.ifa_data is rw;
}


multi sub get_interfaces('linux', :$ipv6, :$loopback, :$active, :$ip --> Array) is export {

    my Pointer $data .= new;
    my int32 $status = getifaddrs($data);

    if $status == -1 { # TODO throw Exception
        return Nil;
    }

    my $ifaces = nativecast(IfAddrs, $data);
    my @data;
    my %iface-info;
    my %routes = (
        4 => get_routes.grep({$_}).grep(*<Gateway> ne '0.0.0.0').map({ $_<Iface> => $_ }).Hash,
        6 => get_routes(:ipv6).grep({$_}).grep(*<Gateway> ne ':').map({ $_<Iface> => $_ }).Hash
    );

    CATCH {
        when X::Sys::IP::Routes::NotSupported { # default route is not implemented
            .resume
        }
    }

    while $ifaces -> $if {
        NEXT $ifaces = $if.ifa_next; # move iterator

        # If is up and running, only IP interfaces
        if (($active and $if.ifa_flags +& (IFF_UP +| IFF_RUNNING)) || !$active) and $if.ifa_addr.sa_family == AF_INET | AF_INET6 {

            next if !$loopback && $if.ifa_flags +& IFF_LOOPBACK; # Ignore loopback

            my ( $ip, $mask, $bcast, $ptp ) = do given $if.ifa_addr.sa_family {
                when AF_INET {
                    nativecast(SockAddr-in, $if.ifa_addr).address,
                    nativecast(SockAddr-in, $if.ifa_netmask).address,
                    $if.ifa_ifu && $if.ifa_ifu.sa_family +& IFF_BROADCAST && $if.ifa_flags +^ IFF_POINTOPOINT ??
                        nativecast(SockAddr-in, $if.ifa_ifu).address !! Nil,
                    $if.ifa_ifu && $if.ifa_ifu.sa_family +& IFF_BROADCAST && $if.ifa_flags +& IFF_POINTOPOINT ??
                        nativecast(SockAddr-in, $if.ifa_ifu).address !! Nil,
                }
                when AF_INET6 {
                    next unless $ipv6;
                    nativecast(SockAddr-in6, $if.ifa_addr).address,
                    nativecast(SockAddr-in6, $if.ifa_netmask).address,
                    $if.ifa_ifu && $if.ifa_ifu.sa_family +& IFF_BROADCAST && $if.ifa_flags +^ IFF_POINTOPOINT ??
                        nativecast(SockAddr-in, $if.ifa_ifu).address !! Nil,
                    $if.ifa_ifu && $if.ifa_ifu.sa_family +& IFF_BROADCAST && $if.ifa_flags +& IFF_POINTOPOINT ??
                        nativecast(SockAddr-in, $if.ifa_ifu).address !! Nil,
                }
                when AF_PACKET && (!$active||!$ip) {next} # not active and IP missing ( for ex DHCP )
                when AF_PACKET { # AF_LINK in BSD TODO add macaddr     if(ioctl(sck, SIOCGIFHWADDR, item) < 0) {
                    %iface-info{ $if.ifa_name } = %( "MAC" => nativecast(SockAddrLL, $if.ifa_addr).address );
                    next;
                }
                default { note "Unknown flags"; next }
            }
            my Int $ip-ver = ($if.ifa_addr.sa_family == AF_INET) ?? 4 !! 6;
            @data.push( %(
                name        => $if.ifa_name,
                ip-addr     => $ip    // '',
                ip-version  => $ip-ver,
                mask        => $mask  // '',
                broadcast   => $bcast // '',
                ptp-dest    => $ptp   // '',
                multicast   => ($if.ifa_addr.sa_family +& IFF_MULTICAST).Bool,
                loopback    => ($if.ifa_flags +& IFF_LOOPBACK).Bool,
                gw-ip       => get_route( $ip-ver, $if.ifa_name, %routes ) // '',
                iface-flags => $if.ifa_flags.Int
            ) );
        } else {
#            say $if.ifa_flags;
        }
    }
    freeifaddrs($data);

    return @data
}

sub get_route( Int $ip-version, Str $iface, %routes --> Str ){

    if %routes{$ip-version}{$iface}<Gateway> && %routes{$ip-version}{$iface}<Gateway>.chars > 5 {
        return %routes{$ip-version}{$iface}<Gateway>,
    }
    Nil
}
