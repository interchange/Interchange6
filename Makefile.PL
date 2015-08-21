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
        'aliased'    => 0,
        'Test::More' => 0,
        'Test::Most' => 0,
        # warning feature was introduced in this release (GH #25)
        'Test::Warnings' => '0.005',
    },
    PREREQ_PM => {
        'namespace::clean' => 0,
        'Moo' => '1.004005',
        'MooseX::CoverableModifiers' => 0.30,
        'MooX::HandlesVia' => 0,
        'MooX::Types::MooseLike' => 0,
        'DateTime' => 0,
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Interchange6-*' },
    test          => { TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/Interchange6.git',
            bugtracker => 'https://github.com/interchange/Interchange6/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
