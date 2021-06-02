#!/usr/bin/env raku
use lib 'lib';
use Sys::IP;

for Sys::IP.new(:loopback, :ipv6).get_interfaces -> %iface {
    say "Name: "        ~ %iface<name>;
    say "IP: "          ~ %iface<ip-addr>;
    say "Broadcast: "   ~ %iface<broadcast>;
    say "Mask: "        ~ %iface<mask>;
    say "Gateway: "     ~ %iface<gw-ip>;
    say "Loopback: "    ~ %iface<loopback>;
    say "Multicast: "   ~ %iface<multicast>;
    say "ptp gateway: " ~ %iface<ptp-dest>;
    say "Iface flags: " ~ %iface<iface-flags>;
    say "";
}
