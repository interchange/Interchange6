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
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Most' => 0,
        'Test::Warnings' => 0,
    },
    PREREQ_PM => {
        'Moo' => 0,
        'MooseX::CoverableModifiers' => 0.30,
        'MooX::HandlesVia' => 0,
        'DateTime' => 0,
	'Interchange6::Schema' => 0.040,
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
