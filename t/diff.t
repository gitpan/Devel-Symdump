#!/usr/bin/perl -w

use lib 'lib' ;

use Devel::Symdump ();
BEGIN {
    $SIG{__WARN__}=sub {return "" if $_[0] =~ /used only once/; print @_;};
}

print "1..1\n";

$scalar = 1;
@array  = 1;
%hash   = (A=>B);
%package::hash = (A=>B);
sub package::function {}
open FH, ">/dev/null";
opendir DH, ".";

my $a = Devel::Symdump->rnew;

my($eval) = <<'END';
$scalar2 = 1;
undef @array;
undef %hash;
%hash2 = (A=>B);
$package2::scalar3 = 3;
close FH;
closedir DH;
END

eval $eval;

my $b = Devel::Symdump->rnew;

if ( $a->diff($b) eq 'dirhandles
- main::DH
filehandles
- main::FH
hashes
+ main::hash2
packages
+ package2
scalars
+ main::hash2
+ main::package2::
+ main::scalar2
+ package2::scalar3'
){
    print "ok 1\n";
} else {
    print "not ok:
a
-
", $a->as_string, "
b
-
", $b->as_string, "
diff
----
", $a->diff($b), "\n";
}
