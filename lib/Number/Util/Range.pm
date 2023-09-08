package Number::Util::Range;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

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
        ignore_duplicates => {
            schema => 'true*',
        },
        max_width => {
            schema => 'posint*',
            default => 0,
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'basic, non-numbers ignored',
            args => {
                array => [100, 2, 3, 4, 5, 101, 'foo'],
            },
            result => [100, "2..5", 101, 'foo'],
        },
        {
            summary => 'option: separator',
            args => {
                array => [100, 2, 3, 4, 5, 101],
                separator => '-',
            },
            result => [100, "2-5", 101],
        },
        {
            summary => 'multiple ranges, negative number',
            args => {
                array => [100, 2, 3, 4, 5, 6, 101, 102, -5, -4, -3, -2, 103],
            },
            result => [100, "2..6", 101, 102, "-5..-2", 103],
        },
        {
            summary => 'option: threshold',
            args => {
                array => [100, 2, 3, 4, 5, 101],
                threshold => 5,
            },
            result => [100, 2, 3, 4, 5, 101],
        },
        {
            summary => 'option: ignore_duplicates',
            args => {
                array => [1, 2, 3, 4, 2, 9, 9, 9],
                ignore_duplicates => 1,
            },
            result => ["1..4", 9],
        },
        {
            summary => 'option: max_width',
            args => {
                array => [98, 100..110, 5, 101],
                max_width => 4,
            },
            result => [98, "100..103","104..107","108..110", 2, 3, 4, 5, 101],
        },
    ],
};
sub convert_number_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $threshold = $args{threshold} // 4;
    my $separator = $args{separator} // '..';
    my $ignore_duplicates = $args{ignore_duplicates};
    my $max_width = $args{max_width} // 0;

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $threshold ? ("$buf[0]$separator$buf[-1]") : @buf;
        @buf = ();
    };

    my %seen;
    for my $i (0..$#{$array}) {
        my $el = $array->[$i];

        next if $ignore_duplicates && $seen{$el}++;

        unless ($el =~ /\A-?[0-9]+\z/) { # not an integer
            $code_empty_buffer->();
            push @res, $el;
            next;
        }
        if (@buf) {
            if ($el != $buf[-1]+1) { # breaks current sequence
                $code_empty_buffer->();
            }
            if ( $max_width && @buf >= $max_width ) {
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
