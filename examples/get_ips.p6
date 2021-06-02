#!/usr/bin/env raku
use lib 'lib';
use Sys::IP;

say Sys::IP.new(:loopback, :ipv6).get_ips
