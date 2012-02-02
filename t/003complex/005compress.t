
#    Copyright © 2010 Brandon L Black <blblack@gmail.com>
#
#    This file is part of gdnsd.
#
#    gdnsd is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    gdnsd is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with gdnsd.  If not, see <http://www.gnu.org/licenses/>.
#

# Compression torture testing.
# This tests depends on exact packet sizes, so
# it will need to be updated if our compression
# algorithm (as in, the order we scan packets for
# compression targets, etc) changes in order to
# get better compression.
#
# The one case was hand-analyzed to make sure the
# 814-byte version makes sense.

use _GDT ();
use FindBin ();
use File::Spec ();
use Test::More tests => 4;

my $compt_mxset = [
    'foo.compression-torture.foo.example.com 21600 MX 0 foo.foo.foo.fox.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 1 fox.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 2 bar.foo.foo.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 3 fox.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 4 foo.fooo.foo.fo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 5 foo.fox.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 6 fox.foo.foo.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 7 foo.foo.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 8 foo.fox.foo.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 9 foo.foo.foo.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 10 foo.foo.foo.bar.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 11 foo.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 12 fo.foo.foo.fooo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 13 foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 14 foo.foo.bar.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 15 fooo.foo.foo.fo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 16 foo.fox.foo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 17 foo.foo.fooo.fo.example.com',
    'foo.compression-torture.foo.example.com 21600 MX 18 foo.foo.fox.foo.example.com',
];

my $compt_aset = [
    'foo.foo.foo.fox.example.com 21600 A 192.0.2.178',
    'fox.example.com 21600 A 192.0.2.161',
    'bar.foo.foo.foo.example.com 21600 A 192.0.2.169',
    'fox.foo.example.com 21600 A 192.0.2.163',
    'foo.fooo.foo.fo.example.com 21600 A 192.0.2.173',
    'foo.fox.example.com 21600 A 192.0.2.164',
    'fox.foo.foo.foo.example.com 21600 A 192.0.2.177',
    'foo.foo.foo.example.com 21600 A 192.0.2.165',
    'foo.fox.foo.foo.example.com 21600 A 192.0.2.176',
    'foo.foo.foo.foo.example.com 21600 A 192.0.2.167',
    'foo.foo.foo.bar.example.com 21600 A 192.0.2.168',
    'foo.foo.example.com 21600 A 192.0.2.162',
    'fo.foo.foo.fooo.example.com 21600 A 192.0.2.174',
    'foo.example.com 21600 A 192.0.2.160',
    'foo.foo.bar.foo.example.com 21600 A 192.0.2.170',
    'fooo.foo.foo.fo.example.com 21600 A 192.0.2.171',
    'foo.fox.foo.example.com 21600 A 192.0.2.166',
    'foo.foo.fooo.fo.example.com 21600 A 192.0.2.172',
    'foo.foo.fox.foo.example.com 21600 A 192.0.2.175',
];

$optrr = Net::DNS::RR->new(
    type => "OPT",
    ednsversion => 0,
    name => "",
    class => 1280,
    extendedrcode => 0,
    ednsflags => 0,
);

my $pid = _GDT->test_spawn_daemon(File::Spec->catfile($FindBin::Bin, 'gdnsd.conf'));

my $size = _GDT->test_dns(
    resopts => { udppacketsize => 2048 },
    qname => 'foo.compression-torture.foo.example.com', qtype => 'MX',
    answer => $compt_mxset,
    addtl => [ @$compt_aset, $optrr ],
    stats => [qw/udp_reqs edns udp_edns_big noerror/],
);
is($size, 814, "Packet size as expected");

_GDT->test_kill_daemon($pid);