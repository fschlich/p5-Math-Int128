package inc::MyMakeMaker;

use strict;
use warnings;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_dump => sub {
    my $self = shift;

    my $dump = super();
    $dump .= <<'EOF';
$WriteMakefileArgs{DEFINE} = _int128_define();
EOF

    return $dump;
};

override _build_MakeFile_PL_template => sub {
    my $self     = shift;
    my $template = super();

    $template =~ s/^(WriteMakefile)/_check_for_capi_maker();\n\n$1/m;

    my $extra = do { local $/; <DATA> };
    return $template . $extra;
};

__PACKAGE__->meta()->make_immutable();

1;

__DATA__

use lib 'inc';
use Config::AutoConf;

sub _check_for_capi_maker {
    return unless -d '.git';

    unless ( eval { require Module::CAPIMaker; 1; } ) {
        warn <<'EOF';

  It looks like you're trying to build Math::Int64 from the git repo. You'll
  need to install Module::CAPIMaker from CPAN in order to do this.

EOF

        exit 1;
    }
}

sub _int128_define {
    my $autoconf = Config::AutoConf->new;

    return unless $autoconf->check_default_headers();
    return '-D__INT128' if $autoconf->check_type('__int128');
    return '-DINT128_TI'
        if $autoconf->check_type('int __attribute__ ((__mode__ (TI)))');

    warn <<'EOF';

  It looks like your compiler doesn't support a 128-bit integer type (one of
  "int __attribute__ ((__mode__ (TI)))" or "__int128"). One of these types is
  necessary to compile the Math::Int128 module.

EOF

    exit 1;
}

package MY;

sub init_dirscan {
    my $self = shift;
    $self->SUPER::init_dirscan(@_);
    push @{ $self->{H} }, 'c_api.h'
        unless grep { $_ eq 'c_api.h' } @{ $self->{H} };
    return;
}
