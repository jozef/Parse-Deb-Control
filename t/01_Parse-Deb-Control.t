#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use File::Spec;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Parse::Deb::Control' ) or exit;
}

exit main();

sub main {
	my $parser = Parse::Deb::Control->new(File::Spec->catfile($Bin, 'control', 'control-perl'));
	isa_ok($parser, 'Parse::Deb::Control');
	
	my $content = $parser->content;
	is(
		scalar (grep { ($_ eq 'Package') or ($_ eq 'Source') } @{$parser->structure}),
		10,
		'10 paragraphs in this control file structure',
	);
	is(
		scalar @{$content},
		10,
		'10 paragraphs in this control file',
	);

	my $parser2 = Parse::Deb::Control->new(File::Spec->catfile($Bin, 'control', 'control-perl-simple'));
	my $content2 = $parser2->content;
	is(
		scalar (grep { ($_ eq 'Package') or ($_ eq 'Source') } @{$parser2->structure}),
		2,
		'2 paragraphs in this simple control file structure',
	);
	is(
		scalar @{$content2},
		2,
		'2 paragraphs in this simple control file',
	);
	
	
	return 0;
}

