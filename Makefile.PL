use lib "./lib";
use Devel::Symdump ();
use ExtUtils::MakeMaker;
$Verbose=1 if $ENV{USER} eq "k";

WriteMakefile(
	      NAME => "Devel::Symdump",
	      DISTNAME => "Devel-Symdump",
	      VERSION_FROM => "lib/Devel/Symdump.pm",
	      'clean' => {FILES => '*/*/*~'},
	      'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz', 
			 DIST_DEFAULT => 'ci tardist'},
	     );
