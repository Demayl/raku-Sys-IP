unit module Sys::IP::Routes;

class X::Sys::IP::Routes is Exception {
}

class X::Sys::IP::Routes::Missing is X::Sys::IP::Routes is export {
    has $.path is required;
    method message { return $!path ~ ' is missing' }
}
class X::Sys::IP::Routes::NotSupported is X::Sys::IP::Routes {
    has $.msg is required;
    method message { $!msg }
}

sub get_default_iface is export { # TODO get ipv6
    _default_route_iface( $*VM.osname ); 
}

sub get_routes(Bool :$ipv6) is export {
    _get_routes( $*VM.osname, $ipv6 ?? 'ipv6' !! 'ipv4' );
}

multi sub _get_routes('linux', 'ipv4' --> Array ) is hidden-from-backtrace { # TODO get info from the kernel ?
    my IO::Path $proc-route := '/proc/net/route'.IO;

    X::Sys::IP::Routes::Missing.new( path => $proc-route ).throw unless $proc-route.e && $proc-route.f;

    my Str @cols;
    my Hash @routes;
    for $proc-route.lines -> $line {
        if !@cols.elems {
            @cols = $line.split: /\s+/, :skip-empty;
        } else {
            my @vals = $line.split(/\s+/, :skip-empty);
            @routes.push: (@cols Z (@vals[0],@vals[1,2]>>.&decode_ipv4, @vals[3..6], @vals[7].&decode_ipv4, @vals[8..*]).flat).flat.Hash;
        }
    }

    @routes
}
multi sub _get_routes('linux', 'ipv6' --> Array ) is hidden-from-backtrace { # TODO get info from the kernel ?
    my IO::Path $proc-route := '/proc/net/ipv6_route'.IO;

    X::Sys::IP::Routes::Missing.new( path => $proc-route ).throw unless $proc-route.e && $proc-route.f;

    my Hash @routes;
    for $proc-route.lines -> $line {
        my @vals = $line.split: /\s+/, :skip-empty;
        @routes.push( %(
            Destination         => @vals[0].&decode_ipv6,
            DestinationPrefix   => @vals[1],
            Source              => @vals[2].&decode_ipv6,
            SourcePrefix        => @vals[3],
            Gateway             => @vals[4].&decode_ipv6,
            Metric              => @vals[5].parse-base(16),
            RefCount            => @vals[6],
            UseCount            => @vals[7].parse-base(16),
            Flags               => @vals[8],
            Iface               => @vals[9]
        ));
    }
    @routes
}


multi sub _default_route_iface('linux' --> Str ) is hidden-from-backtrace { # TODO get info from the kernel ?
    my @routes = _get_routes('linux', 'ipv4');
    @routes.grep( *<Destination> eq '0.0.0.0' && *<Mask> eq '0.0.0.0' && *<Flags>.Int +& 0x0003 ).map( *<Iface> ).first; # Route Default GW and usable
}

multi sub _default_route_iface('windows' --> Str) is hidden-from-backtrace { # TODO

    X::Sys::IP::Routes::NotSupported.new( msg => 'Windows is not a supported OS yet').throw;
}

multi sub _default_route_iface($os-name) {
    X::Sys::IP::Routes::NotSupported.new( msg => $os-name ~ ' is not a supported OS').throw;
}


sub decode_ipv4( Str $hex-ip --> Str ) {
    $hex-ip.comb(2).reverse.map(*.parse-base(16)).join(".")
}

sub decode_ipv6( Str $hex-ip --> Str ){ # TODO use Net::IP
    $hex-ip.comb(4).map(*.subst(/^0+/,'0')).join(':').subst(/':0'**3..*/, '::').subst(/':'+$/,':').subst(/':'**3..*/,'::').subst(/^0/,'');
}
