use lib "./lib";
use Devel::Symdump ();
use ExtUtils::MakeMaker;
$Verbose=1 if $ENV{USER} eq "k";
if ($ExtUtils::MakeMaker::VERSION < 5.16) {
    @version = ( VERSION => $Devel::Symdump::VERSION );
} else {
    @version = ( VERSION_FROM => "lib/Devel/Symdump.pm" );
}

WriteMakefile(
	      NAME => "Devel::Symdump",
	      DISTNAME => "Devel-Symdump",
	      @version,
	      'linkext' => {LINKTYPE => '' }, # not needed for MM > 5.00
	      'clean' => {FILES => '*/*/*~'},
	      'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz', 
			 DIST_DEFAULT => 'ci tardist'},
	     );
