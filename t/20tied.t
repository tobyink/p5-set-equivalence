=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence::_Tie works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Set::Equivalence qw(set);

my $set = set(1..5);

is_deeply(
	[ sort @$set ],
	[ sort 1..5 ],
	'@$set',
);

push @$set, 1..10;

is_deeply(
	[ sort @$set ],
	[ sort 1..10 ],
	'push @$set',
);

unshift @$set, 1..20;

is_deeply(
	[ sort @$set ],
	[ sort 1..20 ],
	'unshift @$set',
);

my $elem = pop(@$set);
ok($elem < 21 && $elem > 0, 'pop @$set');
is($set->size, 19, '... reduces size of set');
is(scalar(@$set), 19, '... reflected in scalar(@$set)');

is_deeply(
	[ sort $elem, @$set ],
	[ sort 1..20 ],
	'... seems to have altered $set correctly',
);

@$set = ();
ok($set->is_null, '@$set = ()');

done_testing;
