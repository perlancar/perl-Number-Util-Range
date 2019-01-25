package Number::Util::Range;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(convert_number_sequence_to_range);
our %SPEC;

$SPEC{'convert_number_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in number arrays & convert to range '.
        '(e.g. 100,2,3,4,5,101 -> 100,"2..5",101)',
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        threshold => {
            schema => 'posint*',
            default => 4,
        },
        separator => {
            schema => 'str*',
            default => '..',
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {
                array => [100, 2, 3, 4, 5, 101, 'foo'],
            },
            result => [100, "2..5", 101, 'foo'],
        },
    ],
};
sub convert_number_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $threshold = $args{threshold} // 4;
    my $separator = $args{separator} // '..';

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $threshold ? ("$buf[0]$separator$buf[-1]") : @buf;
        @buf = ();
    };

    for my $i (0..$#{$array}) {
        my $el = $array->[$i];
        unless ($el =~ /\A-?[0-9]+\z/) { # not an integer
            $code_empty_buffer->();
            push @res, $el;
            next;
        }
        if (@buf) {
            if ($el != $buf[-1]+1) { # breaks current sequence
                $code_empty_buffer->();
            }
        }
        push @buf, $el;
    }
    $code_empty_buffer->();

    \@res;
}

1;

# ABSTRACT:

=head1 SEE ALSO

L<Data::Dump> also does something similar when dumping arrays of numbers, e.g.
if you say C<dd [1,2,3,4];> it will dump the array as "[1..4]".

L<String::Util::Range>
