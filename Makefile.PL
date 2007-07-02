use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::UWO::Directory::Student',
    AUTHOR              => 'Jonathan Yu <frequency@cpan.org>',
    VERSION_FROM        => 'lib/WebService/UWO/Directory/Student.pm',
    ABSTRACT_FROM       => 'lib/WebService/UWO/Directory/Student.pm',
    PL_FILES            => {},
    EXE_FILES           => [],
    PREREQ_PM => {
        'LWP::UserAgent' => 2.033,
        'Carp'           => 1.03,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-UWO-Directory-Student-*' },
);

