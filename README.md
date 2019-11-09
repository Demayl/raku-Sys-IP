# raku Sys::IP

[![Build Status](https://travis-ci.org/demayl/raku-Sys-IP.svg?branch=master)](https://travis-ci.org/demayl/raku-Sys-IP)

Get system IP / Interfaces with Raku programming language

## VERSION
WIP

## DESCRIPTION

Get system IP addresses and interfaces.
It doesn't rely on ifconfig/ipconfig etc. It does this by using routing table default route and C ABI.
All method works fine on Linux only ( for now ). BSD is the next target.

## Coming soon
BSD, Windows

## Why not ifconfig / ipconfig
Really ?

## Example

```perl6
use Sys::IP;

# Get system default IP
say Sys::IP.new.get_default_ip(); # 192.168.0.1

# Get all active IP's
say Sys::IP.new.get_ips(); # [ 192.168.0.1, 192.168.0.2 ]

# Get all active interfaces
say Sys::IP.new.get_interfaces(); # [ { name => eth0, ip-addr => 192.168.0.1 }, ...]
```

## Constructor
* `:$ipv6 = False` include ipv6 addresses
* `:$loopback = False` include loopback interface
* `:$active = True` include only active interfaces
* `:$ip = True` include only interfaces with assigned IP address

## Methods

* `new( Bool :$ipv6 = False, Bool :$loopback = False, Bool :$active = True, Bool :$ip = True --> Sys::IP )`
* `get_default_ip( --> Str )` when used with :ipv6 it will return only ipv6 address
* `get_ips( --> Array )`
* `get_interfaces( --> Array[Hash] )`

## Instalation
```
zef install Sys::IP
```

## Testing
```
prove -ve 'perl6 -Ilib'
```
