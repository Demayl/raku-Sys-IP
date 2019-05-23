#!/usr/bin/env perl6
unit class Sys::IP:ver<0.0.1>:auth<github:demayl>;
use Sys::IP::RAW; # get_interfaces
use Sys::IP::Routes; # default_iface

has Bool $.ipv6     = False; # include ipv6 interfaces
has Bool $.loopback = False; # include loopback interface
has Bool $.active   = True;  # include active interfaces
has Bool $.ip       = True;  # include interfaces with a ip

class X::Sys::IP is Exception {
}

method get_interfaces returns Array {
    my @ifaces = get_interfaces($*VM.osname, :$!ipv6, :$!loopback, :$!active, :$!ip);
    @ifaces
}

method get_ips returns Array {

    return Nil if !$!ip; # IP not needed

    my @ips = self.get_interfaces();
    @ips.grep(*<ip-addr>).map(*<ip-addr>).Array;
}

method get_default_ip returns Str {
    return Nil if !$!ip; # IP not needed
    my $iface = get_default_iface();
    self.get_interfaces().grep( *<name> eq $iface ).map(*<ip-addr>).first;
}
