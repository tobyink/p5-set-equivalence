#!/usr/bin/env perl

use v5.16;
use mop; # https://github.com/stevan/p5-mop-redux

# A trait for type constraints and coercions, which are not
# included in MOP by default.
sub type {
	return unless $_[0]->isa('mop::attribute');	
	my ($attr, $type) = @_;
	$attr->bind(
		'before:STORE_DATA',
		$type->has_coercion
			? sub { my $dref = $_[2]; $$dref = $type->assert_coerce($$dref); return }
			: sub { my $dref = $_[2];          $type->assert_valid($$dref);  return }
	);
}

use Types::Standard qw( Str Int InstanceOf );
use Types::Set qw( Set );

class Person {
	has $name is ro, type(Str), overload(q[""]); # PR31
	has $id is ro, type(Int);
	
	method equals ($other) is overload('eq'), overload('==') {
		return $self->id == $other->id;
	}
}

class Band {
	has $name is ro, type(Str);
	has $members is ro, type(Set[InstanceOf["Person"]]) = [];
	
	method add_member ($m) { $members->insert($m) }
	method has_member ($m) { $members->contains($m) }
	method member_count () { $members->size }
}

my $beatles = 'Band'->new(
	name    => 'The Beatles',
	members => [
		'Person'->new(name => 'John Lennon',     id => 301),
		'Person'->new(name => 'Paul McCartney',  id => 302),
		'Person'->new(name => 'George Harrison', id => 303),
		'Person'->new(name => 'Ringo Starr',     id => 304),
	],
);

# A duplicate!
$beatles->add_member(
	'Person'->new(name => 'Richard Starkey', id => 304),
);

say for @{ $beatles->members };
