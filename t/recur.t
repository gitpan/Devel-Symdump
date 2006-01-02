package Acme::Meta;

BEGIN {
  $::Meta::VERSION = $VERSION = 0; # autovivify for perl >= @26370
  $Meta::{'Meta::'} = $main::{'Meta::'};
  $Acme::Meta::{'Meta::'} = $main::{'Meta::'};
}
require Test::More;
my $tests = 3;
Test::More->import( tests => $tests );
exit unless $tests;
Test::More::ok(1);
$Acme::Meta::Meta::Pie = "good";
Test::More::is ($Acme::Meta::Meta::Meta::Meta::Pie, "good");
Test::More::use_ok('Devel::Symdump');
Devel::Symdump->rnew("Acme");

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
