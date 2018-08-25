#!/usr/bin/env perl

use v5.12;
use strict;
use warnings;

use LWP::Simple;
use Data::Dumper;

sub write_file {
	my ($path, $data) = @_;

	open(my $fh, '>', $path) or die "opening file failed: $!";
	print $fh $data;
	close($fh);
}

my $baseurl = "http://tm.qschome.com:8080/tm16";

my $data = get("${baseurl}/versions.xml") or die "get failed: $!";

my ($build) = $data =~ /BuildNumber="(.*?)"/;
my ($image) = $data =~ / URL="(.*?)"/;
my ($checksum) = $data =~ /Checksum="(.*?)"/;

say "$build $checksum ${baseurl}/$image";

write_file("${build}.xml", $data);
