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
    description => <<'MARKDOWN',

This routine accepts an array, finds sequences of numbers in it (e.g. 1, 2, 3),
and converts each sequence into a range ("1..3"). So basically it "compresses" the
sequence (many elements) into a single element.

MARKDOWN
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        min_range_len => {
            schema => ['posint*', min=>2],
            default => 4,
            description => <<'MARKDOWN',

Minimum number of items in a sequence to convert to a range. Sequence that has
less than this number of items will not be converted.

MARKDOWN
        },
        max_range_len => {
            schema => ['posint*',min=>2],
            description => <<'MARKDOWN',

Maximum number of items in a sequence to convert to a range. Sequence that has
more than this number of items might be split into two or more ranges.

MARKDOWN
        },
        separator => {
            schema => 'str*',
            default => '..',
        },
        ignore_duplicates => {
            schema => 'true*',
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
            summary => 'option: min_range_len (1)',
            args => {
                array => [100, 2, 3, 4, 5, 101],
                min_range_len => 5,
            },
            result => [100, 2, 3, 4, 5, 101],
        },
        {
            summary => 'option: min_range_len (2)',
            args => {
                array => [100, 2, 3, 4, 101, 'foo'],
                min_range_len => 3,
            },
            result => [100, "2..4", 101, 'foo'],
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
            summary => 'option: max_range_len (1)',
            args => {
                array => [98, 100..110, 5, 101],
                max_range_len => 4,
            },
            result => [98, "100..103","104..107", 108, 109, 110, 5, 101],
        },
    ],
};
sub convert_number_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $min_range_len = $args{min_range_len}
        // $args{threshold} # old name, DEPRECATED
        // 4;
    my $max_range_len = $args{max_range_len};
    my $separator = $args{separator} // '..';
    my $ignore_duplicates = $args{ignore_duplicates};

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $min_range_len ? ("$buf[0]$separator$buf[-1]") : @buf;
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
            if ($max_range_len && @buf >= $max_range_len) {
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

L<String::Util::Range> also convert sequences of letters to range (e.g.
"a","b","c","d" -> "a..d").
