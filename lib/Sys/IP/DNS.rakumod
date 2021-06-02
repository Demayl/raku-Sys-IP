unit module Sys::IP::DNS;

my IO::Path $linux-resolv := '/etc/resolv.conf'.IO;

sub get_dns_list(Str $OS-name, Bool :$ipv6 = False --> Array) is export {
    my @list = get_dns($OS-name);

    @list
}

multi sub get_dns('linux'){
    my @list = gather for $linux-resolv.lines -> $line {
        if $line.starts-with('nameserver') {
            take $line.split(' ')[1];
        }
    }

    @list
}
