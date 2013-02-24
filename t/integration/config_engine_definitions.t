#!/usr/bin/perl

# mt-aws-glacier - Amazon Glacier sync client
# Copyright (C) 2012-2013  Victor Efimov
# http://mt-aws.com (also http://vs-dev.com) vs@vs-dev.com
# License: GPLv3
#
# This file is part of "mt-aws-glacier"
#
#    mt-aws-glacier is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    mt-aws-glacier is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use utf8;
use Test::More tests => 31;
use Test::Deep;
use lib qw{../lib ../../lib};
use App::MtAws::ConfigEngineNew;
use Carp;
use Data::Dumper;


# validation

{
	my $c  = create_engine();
	$c->define(sub {
		option('myoption');
		validation 'myoption', message('too_high', "%option a% should be less than 30"), sub { $_ < 30 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption', 31);
	cmp_deeply $res->{error_texts}, [q{"--myoption" should be less than 30}], "validation should work"; 
	cmp_deeply $res->{errors}, [{format => 'too_high', a => 'myoption'}], "validation should work"; 
}

{
	my $c  = create_engine();
	$c->define(sub {
		validation option('myoption'), message('too_high', "%option a% should be less than 30"), sub { $_ < 30 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption', 31);
	cmp_deeply $res->{error_texts}, [q{"--myoption" should be less than 30}], "validation should work with option inline"; 
	cmp_deeply $res->{errors}, [{format => 'too_high', a => 'myoption'}], "validation should work with option inline"; 
}

{
	my $c  = create_engine();
	$c->define(sub {
		validation 'myoption', message('too_high', "%option a% should be less than 30"), sub { $_ < 30 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption', 31);
	cmp_deeply $res->{error_texts}, [q{"--myoption" should be less than 30}], "validation should work withithout option"; 
	cmp_deeply $res->{errors}, [{format => 'too_high', a => 'myoption'}], "validation should work withithout option"; 
}

{
	my $c  = create_engine();
	$c->define(sub {
		validation 'myoption', message('too_high', "%option a% should be less than 30"), sub { $_ < 30 };
		validation 'myoption', message('way_too_high', "%option a% should be less than 100 for sure"), sub { $_ < 100 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption', 200);

	cmp_deeply $res->{error_texts}, [q{"--myoption" should be less than 30}, q{"--myoption" should be less than 100 for sure}], "should perform two validations"; 
	cmp_deeply $res->{errors}, [{format => 'too_high', a => 'myoption'}, {format => 'way_too_high', a => 'myoption'}], "should perform two validations"; 
}

# mandatory

{
	my $c  = create_engine();
	$c->define(sub {
		message 'mandatory', "Please specify %option a%";
		options('myoption', 'myoption2');
		command 'mycommand' => sub { mandatory('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	cmp_deeply $res->{error_texts}, [q{Please specify "--myoption"}], "mandatory should work"; 
	cmp_deeply $res->{errors}, [{format => 'mandatory', a => 'myoption'}], "mandatory should work";
}

{
	my $c  = create_engine();
	$c->define(sub {
		message 'mandatory', "Please specify %option a%";
		options('myoption', 'myoption2', 'myoption3');
		command 'mycommand' => sub { mandatory('myoption', 'myoption3') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	cmp_deeply $res->{error_texts}, [q{Please specify "--myoption"}, q{Please specify "--myoption3"}], "should perform first mandatory check out of two"; 
	cmp_deeply $res->{errors}, [{format => 'mandatory', a => 'myoption'}, {format => 'mandatory', a => 'myoption3'}], "should perform first mandatory check out of two";
}

{
	my $c  = create_engine();
	$c->define(sub {
		message 'mandatory', "Please specify %option a%";
		options('myoption', 'myoption2', 'myoption3');
		command 'mycommand' => sub { mandatory(optional('myoption'), 'myoption3') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	cmp_deeply $res->{error_texts}, [q{Please specify "--myoption3"}], "mandatory should work if inner optional() exists"; 
	cmp_deeply $res->{errors}, [{format => 'mandatory', a => 'myoption3'}], "mandatory should work if inner optional() exists";
}

{
	my $c  = create_engine();
	$c->define(sub {
		message 'mandatory', "Please specify %option a%";
		options('myoption', 'myoption2', 'myoption3');
		command 'mycommand' => sub { mandatory(mandatory('myoption'), 'myoption3') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	cmp_deeply $res->{error_texts}, [q{Please specify "--myoption"}, q{Please specify "--myoption3"}], "nested mandatoy should work"; 
	cmp_deeply $res->{errors}, [{format => 'mandatory', a => 'myoption'}, {format => 'mandatory', a => 'myoption3'}], "nested mandatoy should work";
}

# optional

{
	my $c  = create_engine();
	$c->define(sub {
		options('myoption', 'myoption2');
		command 'mycommand' => sub { optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	ok ! defined $res->{errors}, "optional should work";
}

{
	my $c  = create_engine();
	$c->define(sub {
		options('myoption', 'myoption2', 'myoption3');
		command 'mycommand' => sub { optional('myoption', 'myoption3') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	ok !defined $res->{errors}, 'should perform two optional checks'; 
}

{
	my $c  = create_engine();
	$c->define(sub {
		message 'mandatory', "Please specify %option a%";
		options('myoption', 'myoption2', 'myoption3');
		command 'mycommand' => sub { optional(mandatory('myoption'), 'myoption3') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	cmp_deeply $res->{error_texts}, [q{Please specify "--myoption"}], "optional should work right if inner mandatory() exists";
	cmp_deeply $res->{errors}, [{format => 'mandatory', a => 'myoption'}], "optional should work right if inner mandatory() exists";
}

{
	my $c  = create_engine();
	$c->define(sub {
		options('myoption', 'myoption2', 'myoption3');
		command 'mycommand' => sub { optional(optional('myoption'), 'myoption3') };
	});
	my $res = $c->parse_options('mycommand', '-myoption2', 31);
	ok ! defined $res->{errors}, 'nested optional should work'; 
}

# option

{
	my $c  = create_engine();
	$c->define(sub {
		option 'myoption';
		command 'mycommand' => sub { optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption', 31);
	ok ! defined $res->{errors}, "option should work - no errors";
	ok ! defined $res->{error_texts}, "option should work - no errors";
	ok ! defined $res->{warnings}, "option should work - no warnings";
	ok ! defined $res->{warning_texts}, "option should work - no warnings";
	is $res->{command}, 'mycommand', "option should work - right command";
	cmp_deeply($res->{options}, { myoption => 31 }, "option should work should work"); 
}


{
	my $c  = create_engine();
	$c->define(sub {
		option 'myoption';
		option 'myoption';
		command 'mycommand' => sub { optional('myoption') };
	});
	my $res = $c->parse_options('mycommand', '-myoption', 31);
	ok ! defined $res->{errors}, "option should work even if specified twice";
	ok ! defined $res->{warnings}, "option should work even if specified twice";
	is $res->{command}, 'mycommand';
	cmp_deeply($res->{options}, { myoption => 31 }, "option should work even if specified twice");
}


sub create_engine
{
	App::MtAws::ConfigEngineNew->new();
}

1;