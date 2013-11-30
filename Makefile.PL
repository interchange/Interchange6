use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Interchange6',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Interchange6.pm',
    ABSTRACT            => 'Interchange6 Open Source Shop Machine',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moo' => 0,
	    'Interchange6::Schema'     => 0.004,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Interchange6-*' },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/Interchange6.git',
            bugtracker => 'https://github.com/interchange/Interchange6/issues'
        },
    },
);
