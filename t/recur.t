{
  package Acme::Meta;

  use 5.004;
  use strict;

  require Exporter;
  use vars qw($VERSION);

  BEGIN {
    $Meta::{'Meta::'} = $main::{'Meta::'};
    $Acme::Meta::{'Meta::'} = $main::{'Meta::'};
    $^W = 1;
  }
}
use Test::More;
my $tests = 3;
Test::More->import( tests => $tests );
exit unless $tests;
ok(1);
$Acme::Meta::Meta::Pie = "good";
is ($Acme::Meta::Meta::Meta::Meta::Pie, "good");
use_ok('Devel::Symdump');
Devel::Symdump->rnew("Acme");

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
