#!/usr/bin/perl -w

BEGIN { unshift @INC, '.' ;
$SIG{__WARN__}=sub {return "" if $_[0] =~ /used only once/; print @_;};
}

use Devel::Symdump::Export qw(filehandles hashes arrays);

print "1..13\n";

init();

%prefices = qw(
    scalars	$
    arrays	@
    hashes	%
    functions 	&
    unknowns 	*
);
@prefices{qw(filehandles dirhandles packages)}=("") x 3;


format i_am_the_symbol_printing_format_lest_there_be_any_doubt =
Got these @*
  "$t:"
~~ ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  $a

.

$~ = 'i_am_the_symbol_printing_format_lest_there_be_any_doubt';

@a = packsort(filehandles('main'));
$t = 'filehandles';
$a = "@a";
#write;
if ($a eq "main::DATA main::Hmmmm main::STDERR main::STDIN main::STDOUT main::stderr main::stdin main::stdout") {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

@a = packsort(hashes 'main');
$t = 'hashes';
$a = "@a";
#write;
if ($a eq "main::@ main::ENV main::INC main::SIG main::prefices") {
    print "ok 2\n";
} else {
    print "not ok 2: $a\n";
}

@a = packsort(arrays());
$t = 'arrays';
$a = "@a";
#write;
if ($a eq "main::ARGV main::INC main::_ main::a main::m main::syms main::vars") {
    print "ok 3\n";
} else {
    print "not ok 3: $a\n";
}

# A nonsense test as a placeholder
print "ok 4\n";

# This was the original test No 4. perl5.001m has problems with this code
# Once the $@ in eval and $self=$self->foo problems have been ironed out,
# we can return to this test.

#eval { 
#    @a = Devel::Symdump->really_bogus('main');
#};
#$a = $@ ? $@ : "@a";
##write;
#if ($a =~ /^invalid Devel::Symdump method: really_bogus\(\)/) {
#    print "ok 4\n";
#} else {
#    print "not ok 4 ($a)\n";
#}
#
$sob = rnew Devel::Symdump;


#print "\nAll active packages:\n";
#print "\tmain\n";
@m=();
for (active_packages($sob)) {
    push @m, "$_";
}
$a="@m"; 
if ($a =~ /Carp.*Devel.*Devel::Symdump.*Devel::Symdump::Export.*DynaLoader.*Exporter.*Hidden.*big::long::hairy.*funny::little.*strict/) {
    print "ok 5\n";
} else {
    print "[$a]\n";
    print "not ok 5\n";
}

#print "\nAll apparent modules:\n";
@m=();
for (active_modules($sob)) {
    push @m, "$_";
} 
$a="@m"; 
#print "[$a]\n";
if ($a eq "Carp Devel::Symdump Devel::Symdump::Export Exporter strict vars") {
    print "ok 6\n";
} else {
    print "not ok 6: $a\n";
}


# Cannot test on the number of packages and functions because not
# every perl is built the same way. Static perls will reveal more
# packages and more functions being in them
# Testing on >= seems no problem to me, we'll see

# (Time passes) Much less unknowns in version 1.22 (perl5.003_10).

my %Expect=qw(
packages 13 scalars 28 arrays 7 hashes 7 functions 35 filehandles 9
dirhandles 2 unknowns 53
);



$ok=6;

#we don't count the unknowns. Newer perls might have different outcomes
for $type ( qw{
	       packages
	       scalars arrays hashes
	       functions filehandles dirhandles 
	     }){
    next unless @syms = $sob->$type();

    if ($I_REALLY_WANT_A_CORE_DUMP) {
	# if this block execute , mysteriously COREDUMPS at for() below
	# NOT TRUE anymore (watched by Andreas, 15.6.1995)
	@vars = ($type eq 'packages') ? sort(@syms) : packsort(@syms);
    } else {
	if ($type eq 'packages') {
	    @syms = sort @syms;
	} else {
	    @syms = packsort(@syms);
	} 
    }

#    print "\nAll $type visible:\n";
    $ok++;
    if (@syms >= $Expect{$type}) { #See comment above on %Expect
	print "ok $ok\n";
    } else {
	print "not ok $ok\n";
	print "We expected ", 
	$Expect{$type}, 
	" $type, got only ", 
	scalar @syms, 
	":\n";
	for (@syms) {
	    s/^main:://;
	    print "\t", $prefices{$type}, uncontrol($_), "\n";
	} 
    }
} 

sub active_modules {
    my $ob = shift;
    my @modules = ();
    my($pack);
    for $pack ("main", $ob->packages) {
	if (
		defined &{ "$pack\::import"   } 	||
		defined &{ "$pack\::AUTOLOAD" } 	||
		defined @{ "$pack\::ISA"      }	||
		defined @{ "$pack\::EXPORT"   }	||
		defined @{ "$pack\::EXPORT_OK"}
	    )
	{
	    push @modules, $pack;
	} 
    }
    return sort @modules;
}

sub active_packages {
    my $ob = shift;

    my @modules = ();
    my $pack;
    for $pack ($ob->packages) {
	$pob = new Devel::Symdump $pack;
	if ( $pob->scalars()	||
	     $pob->hashes()	||
	     $pob->arrays()	||
	     $pob->functions()	||
	     $pob->filehandles()||
	     $pob->dirhandles()	
	   )
	{
	    push @modules, $pack;
	} 
    } 
    return sort @modules;
}


sub uncontrol { 
    local $_  = $_[0];
    s/([\200-\377])/    'M-' . pack('c', ord($1) & 0177 )  /eg;
    s/([\000-\037\177])/ '^' . pack('c', ord($1) ^  64   ) /eg;
    return $_;
}

sub packsort {
    my (@vars, @pax, @fullnames);

    for (@_) {
        my($pack, $name) = /^(.*::)(.*)$/s;
        push(@vars, $name);
        push(@pax, $pack);
        push(@fullnames, $_);
    } 

    return @fullnames [
		sort { 
                    ($pax[$a] ne 'main::') <=> ($pax[$b] ne 'main::')
			||
                    $pax[$a] cmp $pax[$b] 
                        ||
                    $vars[$a] cmp $vars[$b]
                } 0 .. $#fullnames
             ];
}


sub init {
    $big::long::hairy::thing++;
    sub Devel::testsub {};
    opendir(DOT, '.');
    opendir(funny::little::imadir, '/');
    $i_am_a_scalar_variable = 1;
    open(Hmmmm, ">/dev/null");
    open(Hidden::FH, ">/dev/null");
}


__END__
