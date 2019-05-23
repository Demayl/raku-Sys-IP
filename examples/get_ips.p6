#!/usr/bin/env perl6
use lib 'lib';
use Sys::IP;

say Sys::IP.new(:loopback, :ipv6).get_ips
