package App::CheckDigitsUtils;

use 5.010001;
use strict;
use warnings;

use Algorithm::CheckDigits;
use Perinci::Object;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to check digits (CLI for Algorithm::CheckDigits)',
};

our $schreq_num = ['str*', match=>qr/\A[0-9]+\z/, prefilters=>['Str::remove_nondigit']];

our @known_methods;
our @known_methods_summaries;
{
    my %md = Algorithm::CheckDigits->method_descriptions();
    for (sort keys %md) {
        push @known_methods, $_;
        push @known_methods_summaries, $md{$_};
    }
}

our %argspecs_common = (
    method => {
        schema => ['str*', in=>\@known_methods, 'x.in.summaries'=>\@known_methods_summaries],
        cmdline_aliases => {m=>{}},
    },
);

our %argspecopt_quiet = (
    quiet => {
        summary => "If set to true, don't output message to STDOUT",
        schema => 'bool*',
        cmdline_aliases => {q=>{}},
    },
);

$SPEC{calc_check_digits} = {
    v => 1.1,
    summary => "Calculate check digit(s) of number(s)",
    description => <<'_',

Given a number without the check digit(s), e.g. the first 12 digits of an
EAN-13, generate/complete the check digits.

Keywords: complete

_
    args => {
        %argspecs_common,
        numbers => {
            summary => 'Numbers without the check digit(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'number',
            schema => ['array*', of=>$schreq_num],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    examples => [
        {
            summary => 'Calculate a single EAN-8 number',
            argv => ['-m', 'ean', '9638-507'],
        },
        {
            summary => 'Calculate a couple of EAN-8 numbers, via pipe',
            src_plang => 'bash',
            src => 'echo -e "9638-507\\n1234567" | [[prog]] -m ean',
        },
    ],
};
sub calc_check_digits {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $cd = Algorithm::CheckDigits::CheckDigits($args{method});

    my $res = [200, "OK", []];
    for my $num (@{ $args{numbers} }) {
        push @{$res->[2]}, $cd->complete($num);
    }
    $res;
}

$SPEC{check_check_digits} = {
    v => 1.1,
    summary => "Check the check digit(s) of numbers",
    description => <<'_',

Given a list of numbers, e.g. EAN-8 numbers, will check the check digit(s) of
each number.

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

_
    args => {
        %argspecs_common,
        numbers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'number',
            schema => ['array*', of=>$schreq_num],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        %argspecopt_quiet,
    },
    examples => [
        {
            summary => 'Check a single EAN-8 number (valid, exit code will be zero, message output to STDOUT)',
            argv => ['-m', 'ean', '9638-5074'],
        },
        {
            summary => 'Check a single EAN-8 number (valid, exit code will be zero, no message)',
            argv => ['-m', 'ean', '-q', '9638-5074'],
        },
        {
            summary => 'Check a single EAN-8 number (invalid, exit code is non-zero, message output to STDOUT)',
            argv => ['-m', 'ean', '9638-5070'],
            status => 400,
        },
        {
            summary => 'Check a single EAN-8 number (invalid, exit code is non-zero, no message)',
            argv => ['-m', 'ean', '-q', '9638-5070'],
            status => 400,
        },
        {
            summary => 'Check a couple of EAN-8 numbers, via pipe, JSON output',
            src_plang => 'bash',
            src => 'echo -e "9638-5074\\n12345678" | [[prog]] -m ean --json',
        },
    ],
};
sub check_check_digits {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $cd = Algorithm::CheckDigits::CheckDigits($args{method});
    my $envres = envresmulti();
    for my $num (@{ $args{numbers} }) {
        if (!$cd->is_valid($num)) {
            $envres->add_result(400, "Incorrect check digit(s)", {item_id=>$num}) ;
            print "$num is INVALID (incorrect check digit(s))\n" unless $args{quiet};
        } else {
            $envres->add_result(200, "OK", {item_id=>$num});
            print "$num is valid\n" unless $args{quiet};
        }
    }
    $envres->as_struct;
}

$SPEC{list_check_digits_methods} = {
    v => 1.1,
    summary => "List methods supported by Algorithm::CheckDigits",
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            summary => 'List methods',
            argv => [],
        },
        {
            summary => 'List methods with their summaries/descriptions',
            argv => ['-l'],
        },
    ],
};
sub list_check_digits_methods {
    my %args = @_;

    if ($args{detail}) {
        my @rows;
        for (0 .. $#known_methods) {
            push @rows, {method=>$known_methods[$_], summary=>$known_methods_summaries[$_]};
        }
        [200, "OK", \@rows, {'table.fields'=>[qw/method summary/]}];
    } else {
        [200, "OK", \@known_methods];
    }
}
1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to EAN
(International/European Article Number):

#INSERT_EXECS_LIST


=head1 SEE ALSO

More general utilities related to check digits: L<App::CheckDigitsUtils>
