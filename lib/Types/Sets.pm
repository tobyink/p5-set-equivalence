package Types::Sets;

use 5.008;
use strict;
use warnings;

BEGIN {
	$Types::Set::AUTHORITY = 'cpan:TOBYINK';
	$Types::Set::VERSION   = '0.000_02';
}

use Set::Equivalence ();
use Type::Tiny 0.015;
use Type::Library -base, -declare => qw(Set AnySet MutableSet ImmutableSet);
use Types::Standard qw(ArrayRef InstanceOf HasMethods);
use Type::Utils -all;

declare Set,
	as InstanceOf['Set::Equivalence'],
	_params(Set);

declare AnySet,
	as HasMethods[qw( insert delete members contains )];

declare MutableSet,
	as Set,
	where { $_->is_mutable },
	inline_as { ( undef, "$_\->is_mutable" ) },
	_params(MutableSet);

declare ImmutableSet,
	as Set,
	where { $_->is_immutable },
	inline_as { ( undef, "$_\->is_immutable" ) },
	_params(ImmutableSet);

coerce Set,
	from ArrayRef, q{ 'Set::Equivalence'->new(members => $_) },
	from AnySet,   q{ 'Set::Equivalence'->new(members => [$_->members]) },
	;

coerce AnySet,
	from ArrayRef, q{ 'Set::Equivalence'->new(members => $_) },
	;

coerce MutableSet,
	from ImmutableSet, q{ $_->clone },
	from ArrayRef,     q{ 'Set::Equivalence'->new(members => $_) },
	from AnySet,       q{ 'Set::Equivalence'->new(members => [$_->members]) },
	;

coerce ImmutableSet,
	from MutableSet, q{ $_->clone->make_immutable },
	from ArrayRef,   q{ 'Set::Equivalence'->new(mutable => !!0, members => $_) },
	from AnySet,     q{ 'Set::Equivalence'->new(mutable => !!0, members => [$_->members]) },
	;

# Crazy stuff for parameterization...
sub _params
{
	my $basetype = shift;
	
	return(
		constraint_generator => sub {
			my $parameter = Types::TypeTiny::TypeTiny->(shift);
			return sub {
				my $tc = $_->type_constraint;
				Scalar::Util::blessed($tc) and $tc->can('is_a_type_of') and $tc->is_a_type_of($parameter);
			};
		},
		inline_generator => sub {
			our %REFADDR;
			my $parameter = Types::TypeTiny::TypeTiny->(shift);
			my $refaddr   = Scalar::Util::refaddr($parameter);
			$REFADDR{$refaddr} = $parameter;
			return sub {
				return (
					undef,
					"do { my \$tc = $_\->type_constraint; Scalar::Util::blessed(\$tc) and \$tc->can('is_a_type_of') and \$tc->is_a_type_of(\$Types::Sets::REFADDR{$refaddr}) }",
				);
			};
		},
		coercion_generator => sub {
			my ($parent, $child, $parameter) = @_;
			my $coercions = 'Type::Coercion'->new( type_constraint => $child );
			my $immute = ($parent->name =~ /^Immutable/);
			
			if ($parameter->has_coercion) {
				$coercions->add_type_coercions(
					ArrayRef() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							coerce               => 1,
							members              => [ map $parameter->coerce($_), @$in ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					Set() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							coerce               => 1,
							equivalence_relation => $in->equivalence_relation,
							members              => [ map $parameter->coerce($_), $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					AnySet() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							coerce               => 1,
							members              => [ map $parameter->coerce($_), $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
			}
			else {
				$coercions->add_type_coercions(
					ArrayRef() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint => $parameter,
							members         => $in,
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					Set() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							equivalence_relation => $in->equivalence_relation,
							members              => [ $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
				$coercions->add_type_coercions(
					AnySet() => sub {
						my $in  = $_;
						my $set = 'Set::Equivalence'->new(
							type_constraint      => $parameter,
							members              => [ $in->members ],
						);
						$immute ? $set->make_immutable : $set;
					},
				);
			}
			
			$coercions->add_type_coercions(
				$parameter => sub {
					my $in  = $_;
					my $set = 'Set::Equivalence'->new(
						type_constraint      => $parameter,
						coerce               => $parameter->has_coercion,
						members              => [ $in ],
					);
					$immute ? $set->make_immutable : $set;
				},
			) unless $parameter->is_a_type_of(Set());
		},
	);
}

1;
