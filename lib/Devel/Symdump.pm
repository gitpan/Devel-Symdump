# Copyright 1995 by Andreas Koenig (see AUTHOR below)
# Permission is granted to use and copy this piece of code under the
# same conditions as perl itself.

# Major hacks by tchrist.

package Devel::Symdump;

use 5.003;
use strict;
use vars qw($Defaults $VERSION);

$Defaults = {
    'RECURS' => 0,
    'AUTOLOAD' => {
	'packages'	=> 1,
	'scalars'	=> 1,
	'arrays'	=> 1,
	'hashes'	=> 1,
	'functions'	=> 1,
	'filehandles'	=> 1,
	'dirhandles'	=> 1,
	'unknowns'	=> 1,
	}
};

$VERSION = '1.22'; #avoid warning

# Revision is not linked to $VERSION anymore
# $Id: Symdump.pm,v 1.29 1996/12/02 01:11:51 k Exp $

$Defaults = $Defaults;

use Carp;
# use strict;

sub rnew {
    my($class,@packages) = @_;
    no strict "refs";
    my $self = bless {%${"$class\:\:Defaults"}}, $class;
    $self->{RECURS}++;
    $self->_doit(@packages);
}

sub new {
    my($class,@packages) = @_;
    no strict "refs";
    my $self = bless {%${"$class\:\:Defaults"}}, $class;
    $self->_doit(@packages);
}

sub _doit {
    my($self,@packages) = @_;
    # The following line should be
    # @packages = ("main") unless defined(@packages);
    # but currently works around a bug in perl5.001 with defined() in reentered scope 
    @packages = ("main") unless defined(@packages) && @packages>0;
    $self->{RESULT} = $self->_symdump(@packages);
    return $self;
}

sub _symdump {
    my($self,@packages) = @_ ;
    my($key,$val,$num,$pack,@todo,$tmp);
    my $result = {};
    foreach $pack (@packages){
	no strict;
#	local(*stab) = *{"$pack\::"};
	while (($key,$val) = each(%{*{"$pack\::"}})) {
	    my $gotone = 0;
	    #### SCALAR ####
	    if (defined $val && defined *{$val}{SCALAR}) {
		$result->{$pack}{SCALARS}{$key}++;
		$gotone++;
	    }
	    #### ARRAY ####
	    if (defined $val && defined *{$val}{ARRAY}) {
		$result->{$pack}{ARRAYS}{$key}++;
		$gotone++;
	    }
	    #### HASH ####
	    if (defined $val && defined *{$val}{HASH} && $key !~ /::/) {
		$result->{$pack}{HASHES}{$key}++;
		$gotone++;
	    }
	    #### PACKAGE ####
	    if (defined $val && defined *{$val}{HASH} && $key =~ /::$/ &&
		    $key ne "main::" )
	    {
		my($p) = $pack ne "main" ? "$pack\::" : "";
		($p .= $key) =~ s/::$//;
		$result->{$pack}{PACKAGES}{$p}++;
		$gotone++;
		push @todo, $p;
	    }
	    #### FUNCTION ####
	    if (defined $val && defined *{$val}{CODE}) {
		$result->{$pack}{FUNCTIONS}{$key}++;
		$gotone++;
	    }
	    #### FILEHANDLE ####
	    if (defined $val && defined fileno(*{$val}{FILEHANDLE})){
		$result->{$pack}{FILEHANDLES}{$key}++;
		$gotone++;
	    }
	    #### DIRHANDLE ####
	    if (defined $val && defined telldir(*{$val})){
		$result->{$pack}{DIRHANDLES}{$key}++;
		$gotone++;
	    }
	    #### SOMETHING ELSE ####
	    unless ($gotone) {
		$result->{$pack}{UNKNOWNS}{$key}++;
	    }
	}
    }

    return (@todo && $self->{RECURS})
		? { %$result, %{$self->_symdump(@todo)} }
		: $result;
}

sub _partdump {
    my($self,$part)=@_;
    my ($pack, @result);
    my $prepend = "";
    foreach $pack (keys %{$self->{RESULT}}){
	$prepend = "$pack\::" unless $part eq 'PACKAGES';
	push @result, map {"$prepend$_"} keys %{$self->{RESULT}{$pack}{$part} || {}};
    }
    return @result;
}

# this is needed so we don't try to AUTOLOAD the DESTROY method
sub DESTROY {}

sub as_string {
    my $self = shift;
    my($type,@m);
    for $type (sort keys %{$self->{'AUTOLOAD'}}) {
	push @m, $type;
	push @m, "\t" . join "\n\t", map {
	    s/([\000-\037\177])/ '^' . pack('c', ord($1) ^ 64) /eg;
	    $_;
	} sort $self->_partdump(uc $type);
    }
    return join "\n", @m;
}

sub as_HTML {
    my $self = shift;
    my($type,@m);
    push @m, "<TABLE>";
    for $type (sort keys %{$self->{'AUTOLOAD'}}) {
	push @m, "<TR><TD valign=top><B>$type</B></TD>";
	push @m, "<TD>" . join ", ", map {
	    s/([\000-\037\177])/ '^' .
		pack('c', ord($1) ^ 64)
		    /eg; $_;
	} sort $self->_partdump(uc $type);
	push @m, "</TD></TR>";
    }
    push @m, "</TABLE>";
    return join "\n", @m;
}

sub diff {
    my($self,$second) = @_;
    my($type,@m);
    for $type (sort keys %{$self->{'AUTOLOAD'}}) {
	my(%first,%second,%all,$symbol);
	foreach $symbol ($self->_partdump(uc $type)){
	    $first{$symbol}++;
	    $all{$symbol}++;
	}
	foreach $symbol ($second->_partdump(uc $type)){
	    $second{$symbol}++;
	    $all{$symbol}++;
	}
	my(@typediff);
	foreach $symbol (sort keys %all){
	    next if $first{$symbol} && $second{$symbol};
	    push @typediff, "- $symbol" unless $second{$symbol};
	    push @typediff, "+ $symbol" unless $first{$symbol};
	}
	foreach (@typediff) {
	    s/([\000-\037\177])/ '^' . pack('c', ord($1) ^ 64) /eg;
	}
	push @m, $type, @typediff if @typediff;
    }
    return join "\n", @m;
}

AUTOLOAD {
    my($self,@packages) = @_;
    unless (ref $self) {
#	$self = $self->new(@packages); # perl5.001m might have a bug that doesn't allow this (?)
	my $tself;
	$tself = $self->new(@packages);
	$self = $tself;
    }
    no strict "vars";
    (my $auto = $AUTOLOAD) =~ s/.*:://;

    unless ($self->{'AUTOLOAD'}{$auto}) {
	croak "invalid Devel::Symdump method: $auto()";
    }

    my @syms = $self->_partdump(uc $auto);
    return @syms; # make sure now it gets context right
}

1;

__END__

=head1 NAME

Devel::Symdump - dump symbol names or the symbol table

=head1 SYNOPSIS

    # Constructor
    require Devel::Symdump;
    @packs = qw(some_package another_package);
    $obj = Devel::Symdump->new(@packs);        # no recursion
    $obj = Devel::Symdump->rnew(@packs);       # with recursion
	
    # Methods
    @array = $obj->packages;
    @array = $obj->scalars;
    @array = $obj->arrays;
    @array = $obj->hashs;
    @array = $obj->functions;
    @array = $obj->filehandles;
    @array = $obj->dirhandles;
    @array = $obj->unknowns;
	
    $string = $obj->as_string;
    $string = $obj1->diff($obj2);

    # Methods with autogenerated objects
    # all of those call new(@packs) internally
    @array = Devel::Symdump->packages(@packs);
    @array = Devel::Symdump->scalars(@packs);
    @array = Devel::Symdump->arrays(@packs);
    @array = Devel::Symdump->hashes(@packs);
    @array = Devel::Symdump->functions(@packs);
    @array = Devel::Symdump->filehandles(@packs);
    @array = Devel::Symdump->dirhandles(@packs);
    @array = Devel::Symdump->unknowns(@packs);

=head1 DESCRIPTION

This little package serves to access the symbol table of perl.

=over 4

=head2 C<Devel::Symdump-E<gt>rnew(@packages)>
returns a symbol table object for all subtrees below @packages.
Nested Modules are analyzed recursively. If no package is given as
argument, it defaults to C<main>. That means to get the whole symbol
table, just do a C<rnew> without arguments.

=head2 C<Devel::Symdump-E<gt>new(@packages)>
does not go into recursion and only analyzes the packages that are
given as arguments.

The methods packages(), scalars(), arrays(), hashes(), functions(),
filehandles(), dirhandles(), and unknowns() each return an array of
fully qualified symbols of the specified type in all packages that are
held within a Devel::Symdump object, but without the leading C<$>,
C<@> or C<%>.  In a scalar context, they will return the number of
such symbols.  Unknown symbols are usually either formats or variables
that haven't yet got a defined value.

As_string() prints a simple string representation of the object.

Diff() prints the difference between two Devel::Symdump objects in
human readable form. The format is similar to the one used by the
as_string method.

=head1 SUBCLASSING

The design of this package is intentionally primitiv and allows it to
be subclassed easily. An example of a useful subclass is
Devel::Symdump::Export, a package which exports all methods of the
Devel::Symdump package and turns them into functions.

=head1 AUTHORS

Andreas Koenig F<E<lt>koenig@franz.ww.TU-Berlin.DEE<gt>> and Tom
Christiansen F<E<lt>tchrist@perl.comE<gt>>.  Based on the old
F<dumpvar.pl> by Larry Wall.

=head1 VERSION

This release is $Revision: 1.29 $.

=cut
