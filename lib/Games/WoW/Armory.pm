package Games::WoW::Armory;

use warnings;
use strict;
use Carp;
use base qw(Class::Accessor::Fast);
use LWP::UserAgent;
use XML::Simple;

__PACKAGE__->mk_accessors(
        qw(character url reputation skill profession characterinfo members) );

our $VERSION = '0.0.1';

=head1 NAME

Games::WoW::Armory - Access to the WoW Armory


=head1 VERSION

version


=head1 SYNOPSIS

    use Games::WoW::Armory;

  	methods
  
=head1 DESCRIPTION

desc

=cut

our $WOW_EUROPE = "http://armory.wow-europe.com/";
our $WOW_US     = 'http://armory.worldofwarcraft.com/';

=head2 fetch_data
fetch the data for the url
store the result in $self->{data}
=cut

sub fetch_data {
    my ( $self, $params ) = @_;
    $self->{ ua } = LWP::UserAgent->new() || croak $!;
    $self->{ ua }->agent(
        "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1"
    );

    my $base_url;
    if ( $$params{ country } eq "EU" ) {
        $base_url = $WOW_EUROPE;
    } elsif ( $$params{ country } eq "US" ) {
        $base_url = $WOW_US;
    } else {
        croak "Unknow region code, please choose US or EU";
    }

    $self->url(   $base_url
                . $$params{ xml } . "?r="
                . $$params{ realm } . "&n="
                . $$params{ name } );

    $self->{ resultat } = $self->{ ua }->get( $self->url );

    $self->{ xp }   = XML::Simple->new;
    $self->{ data } = $self->{ xp }->XMLin( $self->{ resultat }->content );
}

=head2 search_character
search a character
required params : realm | character | country
realm : name of the realm
character : name of a character
country : name of the country (EU|US)
The character information are in $self->character (name, race, guild, etc)
The character reputations are in $self->reputation
The character skills are in $self->skill
More character informations are in $self->characterinfo
=cut

sub search_character {
    my ( $self, $params ) = @_;

    my $xml = "character-sheet.xml";

    croak "you need to specify a character name"
        unless defined $$params{ character };
    croak "you need to specify a realm" unless defined $$params{ realm };
    croak "you need to specify a country name"
        unless defined $$params{ country };

    $self->fetch_data( { xml     => $xml,
                         realm   => $$params{ realm },
                         name    => $$params{ character },
                         country => $$params{ country } } );

    $self->character( $self->{ data }{ characterInfo }{ character } );
    $self->reputation( $self->{ data }{ characterInfo }{ reputationTab } );
    $self->skill( $self->{ data }{ characterInfo }{ skillTab } );
    $self->characterinfo( $self->{ data }{ characterInfo }{ characterTab } );

}

=head2 search_guild
search a guild
required params : realm | guild | country
realm : name of the realm
guild : name of the guild
country : name of the country (EU|US)
Guild members are in $self->members
=cut 

sub search_guild {
    my ( $self, $params ) = @_;

    my $xml = "guild-info.xml";

    croak "you need to specify a guild name" unless defined $$params{ guild };
    croak "you need to specify a realm"      unless defined $$params{ realm };
    croak "you need to specify a country name"
        unless defined $$params{ country };

    $self->fetch_data( { xml     => $xml,
                         realm   => $$params{ realm },
                         name    => $$params{ guild },
                         country => $$params{ country } } );

    $self->members(
              $self->{ data }{ guildInfo }{ guild }{ members }{ character } );

}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-games-wow-armory@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

franck cuny  C<< <franck.cuny@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, franck cuny C<< <franck.cuny@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;

__END__
