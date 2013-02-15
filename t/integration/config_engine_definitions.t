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
use Test::More tests => 3;
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
		validation 'myoption', 'concurrency should be less than 30', sub { $_ < 30 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my (@res) = $c->parse_options('mycommand', '-myoption', 31);
	ok check_error('concurrency should be less than 30', @res), "validation should work with option"
}

{
	my $c  = create_engine();
	$c->define(sub {
		validation option('myoption'), 'concurrency should be less than 30', sub { $_ < 30 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my (@res) = $c->parse_options('mycommand', '-myoption', 31);
	ok check_error('concurrency should be less than 30', @res), "validation should work with option inline"
}

{
	my $c  = create_engine();
	$c->define(sub {
		validation 'myoption', 'concurrency should be less than 30', sub { $_ < 30 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my (@res) = $c->parse_options('mycommand', '-myoption', 31);
	ok check_error('concurrency should be less than 30', @res), "validation should work withithout option"
}

{
	my $c  = create_engine();
	$c->define(sub {
		validation 'myoption', 'concurrency should be less than 30', sub { $_ < 30 };
		validation 'myoption', 'concurrency should be less than 100 for sure', sub { $_ < 100 };
		command 'mycommand' => sub { validate optional('myoption') };
	});
	my ($errors) = $c->parse_options('mycommand', '-myoption', 200);
	ok $errors && $errors->[0] eq 'concurrency should be less than 30', 'should perform first validation out of two';
	ok $errors && $errors->[1] eq 'concurrency should be less than 100 for sure', 'should perform second validation out of two';
}

sub create_engine
{
	App::MtAws::ConfigEngineNew->new();
}

sub check_error
{
	my ($text, $errors) = @_;
	!! ($errors && $errors->[0] eq $text);
}

1;