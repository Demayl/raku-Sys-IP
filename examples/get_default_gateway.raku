#!/usr/bin/env raku
use lib '../lib';
use Sys::IP;


my @gws = Sys::IP.new.get_interfaces.map({%(IP => $_<ip-addr>, GW => $_<gw-ip>, IFACE => $_<name>)});

say @gws
