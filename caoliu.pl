#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib '/secure/Common/src/cpan';
use Encode;
use Getopt::Long;
use Data::Dumper;
use HTML::LinkExtractor;
use HTML::Entities;
use Term::ProgressBar;
use LWP::UserAgent;
use DBD::SQLite;

binmode(STDOUT, ':encoding(utf8)');

my %opts = (
    'file'    => '/run/shm/caoliu.db',
    'pages'   => 100,
    'server'  => 'http://184.154.128.244',
    'proxy'   => undef,
);

GetOptions (\%opts, 'file|f=s', 'pages|p=i', 'server|s=s', 'proxy=s', 'help|h');

my $ua = LWP::UserAgent->new (agent => 'Mozilla/4.0');
my $LX = new HTML::LinkExtractor;
my $dbh = DBI->connect ("dbi:SQLite:dbname=" . $opts{file}, "", "", {RaiseError => 1});
$dbh->prepare ("CREATE TABLE IF NOT EXISTS page (url text primary key, title text, referrer text)")->execute ();

$ua->proxy ($opts{proxy}) if $opts{proxy};

####
print "Saving to $opts{file}\n";
my $progress = Term::ProgressBar->new ({count => $opts{pages}});

for my $page (1..$opts{pages})
{
    my $r = $ua->get ($opts{server} .'/thread0806.php?fid=15&page=' . $page);
    $LX->parse (\$r->content);

    my @links = grep { $$_{href} and $$_{href} =~ /^htm_data/ } @{$LX->links};

    for (@links)
    {
        my ($line, $href) = ($$_{_TEXT}, $$_{href});
        my $subpage = "$opts{server}/$href";

        s#</a>.*##, s#.*>## for $line;
        $line = decode_entities (decode ("gbk", $line));
        next unless $line =~ /^\[/;

        my $r2 = $ua->get ($subpage);
        $LX->parse (\$r2->content);

        my @downurls = grep { $$_{href} and $$_{href} =~ /(xunfs|rmdown|yfdisk)/ } @{$LX->links};
        my $rmdown;
        for (@downurls)
        {
            # Type A: http://www.viidii.com/?http://www______rmdown______com/link______php?hash=1318ab66bae234c926894398869edd13822b995c37b&z
            if ($$_{href} =~ /(?:xunfs|rmdown).*php\?hash=(\w+)/)
            {
                $rmdown = $1;
                last;
            }
        }

        $rmdown = "-" if ! defined $rmdown;

        print "Found $line: $rmdown\n";
        $dbh->prepare ("INSERT OR REPLACE INTO page (title, url, referrer) values (?, ?, ?)")->execute ($line, $rmdown, $href);
    }
}

$dbh->finish ();
$dbh->disconnect ();
