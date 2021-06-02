#!/usr/bin/env raku
use lib 'lib';
use Sys::IP;

say Sys::IP.new.get_default_ip
