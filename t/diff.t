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

$scalar2 = 1;
undef @array;
undef %hash;
%hash2 = (A=>B);
eval '
%package2::scalar3 = 1;
';
close FH;
closedir DH;

my $b = Devel::Symdump->rnew;

if ( $a->diff($b) eq 'arrays
- main::array
dirhandles
- main::DH
filehandles
- main::FH
hashes
- main::hash
+ main::hash2
packages
+ package2
scalars
+ main::scalar2
unknowns
+ main::DH
+ main::FH
+ main::array
+ main::hash
- main::hash2
- main::scalar2
+ package2::scalar3'){
    print "ok 1\n";
} else {
    print "not ok: diff is >>", $a->diff($b), "<<\n";
}
