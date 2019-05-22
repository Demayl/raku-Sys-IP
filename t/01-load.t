use v6;
use Test;
use lib 'lib';
plan 2;
use Sys::IP;
ok "Load", "Loaded";
ok Sys::IP.new, "Constructor works";
