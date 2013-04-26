#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use autodie qw/open/;

#binmode (STDOUT, ':encoding(utf8)');
$| = 1;

sub rmdown_to
{
    my ($hash, $output) = @_;

    my $postUrl = 'http://www.rmdown.com/download.php';
    my $getUrl = 'http://www.rmdown.com/link.php?hash=' . $hash;
    my %form = ();

    my $ua = LWP::UserAgent->new (agent => "Mozilla/5.0");
    $ua->default_header ('Origin' => 'www.rmdown.com');
    $ua->default_header ('Referrer' => $getUrl);

    my $resp = $ua->get ($getUrl);
    die $@ unless $resp->is_success;

    for (split /</, $resp->content)
    {
        if ($_ =~ /value="([a-zA-Z0-9=]+)"/)
        {
            if (defined ($form{ref}))
            {
                $form{reff} = $1;
            }
            else
            {
                $form{ref} = $1;
            }
        }
    }

    $resp = $ua->post ($postUrl, \%form);
    die $@ unless $resp->is_success;
    
    open my $fh, '>', $output;
    print $fh $resp->content;
};

my $id = shift or die "usage: rmdown [ id | rmdown.com/link.php?hash= ]";

if ($id =~ /([0-9a-zA-Z]{10,})$/)
{
    $id = $1;
}
elsif ($id =~ /hash=([0-9a-zA-Z]+)/)
{
    $id = $1;
}
else
{
    die "Invalid url: $id\n";
}

my $out = shift || "$id.torrent";

rmdown_to ($id, $out);
print "$out saved.\n";
