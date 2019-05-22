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

sub get_default_iface is export {
    _default_route_iface( $*VM.osname ); 
}

sub get_routes is export {
    _get_routes( $*VM.osname );
}

multi sub _get_routes('linux' --> Array ) is hidden-from-backtrace { # TODO get info from the kernel ?
    my IO::Path $proc-route := '/proc/net/route'.IO;

    X::Sys::IP::Routes::Missing.new( path => $proc-route ).throw unless $proc-route.e && $proc-route.f;

    my Str @cols;
    my Hash @routes;
    for $proc-route.lines -> $line {
        if !@cols.elems {
            @cols = $line.split: /\s+/, :skip-empty;
        } else {
            @routes.push: (@cols Z $line.split(/\s+/, :skip-empty)).flat.Hash;
        }
    }

    @routes
}


multi sub _default_route_iface('linux' --> Str ) is hidden-from-backtrace { # TODO get info from the kernel ?
    my @routes = _get_routes('linux');
    @routes.grep( *<Destination> eq '00000000' && *<Mask> eq '00000000' && *<Flags>.Int +& 0x0003 ).map( *<Iface> ).first; # Route Default GW and usable
}

multi sub _default_route_iface('windows' --> Str) is hidden-from-backtrace { # TODO

    X::Sys::IP::Routes::NotSupported.new( msg => 'Windows is not a supported OS yet').throw;
}

multi sub _default_route_iface($os-name) {
    X::Sys::IP::Routes::NotSupported.new( msg => $os-name ~ ' is not a supported OS').throw;
}
