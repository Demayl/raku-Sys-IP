#!/usr/bin/env perl6
use lib 'lib';
use Sys::IP;

say Sys::IP.new.get_default_ip
