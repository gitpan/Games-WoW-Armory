package Games::WoW::Armory;

use warnings;
use strict;
use Carp;
use base qw(Class::Accessor::Fast);
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

__PACKAGE__->mk_accessors(
    qw(character url team guild)
);

our $VERSION = '0.0.5';

=head1 NAME

Games::WoW::Armory - Access to the WoW Armory


=head1 SYNOPSIS

    use Games::WoW::Armory;

    my $armory = Games::WoW::Armory->new();
    $armory->search_character( { realm     => 'Elune',
                                 character => 'Aarnn',
                                 country   => 'EU } );
    print $armory->character->name;
    print $armory->character->race;
    print $armory->character->level;

=head2 METHOD

=head3 fetch_data

Fetch the data, and store the result in $self->{data}

=head3 search_character

Search a character. Required params:

	realm | character | country
	realm : name of the realm
	character : name of a character
	country : name of the country (EU|US)
	
List of accessor for character:
    
name: character name 
guildName: guild name
arenaTeams: list of teams the character is in. Each team in the array is a Games::WoW::Armory::Team object

    foreach my $team (@{$armory->character->arenaTeams}){
        print $team->name;
        foreach my $char (@{$team}){
            print $char->name . " " . $char->race;
        }
    }
    
battleGroup: the battlegroup name 
realm: realm name 
race: race name 
gender: gender of the character 
faction: faction the character belongs to 
level: level of the character 
lastModified: 
title: highest rank in the old PVP mode 
class: class name
rank: rank
teamRank: rank in the team 
seasonGamesPlayed: number of games played in the current season 
seasonGamesWon: number of games win in the current season
heroic_access: list of heroic access for the character
    
    foreach my $key ( @{ $armory->character->heroic_access } ) {
        print "Have access to the $key.\n";
    }

characterinfo: a hash with lot of informations about the character
skill:  a hash with all the skill reputation
reputation: a hash with all the character reputation

=head3 search_guild

Search for a guild. required params : 
	
	realm | guild | country
	realm : name of the realm
	guild : name of the guild
	country : name of the country (EU|US)
	
List of accessor for guild:

realm: name of the realm
name: name of the guild 
battleGroup: name of the battleGroup
members: array with all the member. Each member is a Games::WoW::Armory::Character object.
    
    foreach my $member (@{$armory->guild->members}){
        print $member->name;
    }

=head3 search_team

Search for a team. required params : 
	
	team | ts | battlegroup | country
	battlegroup : name of the battlegroup
	ts : type (2vs2 | 3vs3 | 5vs5) juste the number (eg: ts => 5)
	team : name of the team
	country : name of the country (EU|US)

List of accessor for team:

seasonGamesPlayed: number of games played this season
rating: 
size: number of members in the team
battleGroup: name of the battlegroup
realm: name of the realm
lastSeasonRanking: ranking in the last season
factionId: faction ID, 0 for alliance, 1 for Horde
ranking:
name: name of the team
relevance: 
seasonGamesWon: number of games won
members: team members in an array, all the members are a Games::WoW::Armory::Character object

    foreach my $member (@{$armory->team->members}){
        print $member->name;
    }

=head3 get_heroic_access

Store in $self->character->heroic_access the list of keys the user can buy for the instances in heroic mode.

=cut

our $WOW_EUROPE = "http://armory.wow-europe.com/";
our $WOW_US     = 'http://armory.worldofwarcraft.com/';

our $HEROIC_REPUTATIONS = {
    "Keepers of Time"     => "Key of Time",
    "Lower City"          => "Auchenai Key",
    "The Sha'tar"         => "Warpforged Key",
    "Honor Hold"          => "Flamewrought Key",
    "Thrallmar"           => "Flamewrought Key",
    "Cenarion Expedition" => "Reservoir Key",
};

sub fetch_data {
    my ( $self, $params ) = @_;
    $self->{ ua } = LWP::UserAgent->new() || croak $!;
    $self->{ ua }->agent(
        "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1"
    );

    my $base_url;
    if ( $$params{ country } =~ /eu/i ) {
        $base_url = $WOW_EUROPE;
    }
    elsif ( $$params{ country } =~ /us/i ) {
        $base_url = $WOW_US;
    }
    else {
        croak "Unknow region code, please choose US or EU";
    }

    if ( defined $$params{ battlegroup } ) {
        $self->url( $base_url
                . $$params{ xml } . "?b="
                . $$params{ battlegroup } . "&ts="
                . $$params{ ts } . "&t="
                . $$params{ team } );

    }
    else {
        $self->url( $base_url
                . $$params{ xml } . "?r="
                . $$params{ realm } . "&n="
                . $$params{ name } );

    }

    $self->{ resultat } = $self->{ ua }->get( $self->url );

    $self->{ xp }   = XML::Simple->new;
    $self->{ data } = $self->{ xp }->XMLin( $self->{ resultat }->content );
}

sub search_character {
    my ( $self, $params ) = @_;

    my $xml = "character-sheet.xml";

    croak "you need to specify a character name"
        unless defined $$params{ character };
    croak "you need to specify a realm" unless defined $$params{ realm };
    croak "you need to specify a country name"
        unless defined $$params{ country };

    $self->fetch_data(
        {   xml     => $xml,
            realm   => $$params{ realm },
            name    => $$params{ character },
            country => $$params{ country }
        }
    );
    
    my $character     = $self->{ data }{ characterInfo }{ character };
    my $reputation    = $self->{ data }{ characterInfo }{ reputationTab };
    my $skill         = $self->{ data }{ characterInfo }{ skillTab };
    my $characterinfo = $self->{ data }{ characterInfo }{ characterTab };
    my $arena_team    = $$character{arenaTeams}{arenaTeam};
    
    $self->character( Games::WoW::Armory::Character->new );
    $self->character->name( $$character{ name } );
    $self->character->class( $$character{ class } );
    $self->character->guildName( $$character{ guildName } );

    # $self->arenaTeams
    $self->character->battleGroup( $$character{ battleGroup } );
    $self->character->realm( $$character{ realm } );
    $self->character->race( $$character{ race } );
    $self->character->gender( $$character{ gender } );
    $self->character->faction( $$character{ faction } );
    $self->character->level( $$character{ level } );
    $self->character->lastModified( $$character{ lastModified } );
    $self->character->title( $$character{ title } );

    $self->character->reputation( $reputation );
    $self->character->skill( $skill );
    $self->character->characterinfo( $characterinfo );
    
    my @teams;
    foreach my $team (keys %{$arena_team}){
        my $t = Games::WoW::Armory::Team->new;
        $t->name($team);
        $t->seasonGamesPlayed($$arena_team{$team}{seasonGamesPlayed});
        $t->size($$arena_team{$team}{size});
        $t->rating($$arena_team{$team}{rating});
        $t->battleGroup($$arena_team{$team}{battleGroup});
        $t->realm($$arena_team{$team}{realm});
        $t->lastSeasonRanking($$arena_team{$team}{lastSeasonRanking});
        $t->factionId($$arena_team{$team}{factionId});
        $t->ranking($$arena_team{$team}{ranking});
        $t->seasonGamesWon($$arena_team{$team}{seasonGamesWon});
        my @members;

        my $members = $$arena_team{$team}{members}{character};
        foreach my $member (keys %{$members}){
            my $m = Games::WoW::Armory::Character->new;
            $m->name($member);
            $m->race($$members{$member}{race});
            $m->seasonGamesPlayed($$members{$member}{seasonGamesPlayed});
            $m->teamRank($$members{$member}{teamRank});
            $m->race($$members{$member}{race});
            $m->gender($$members{$member}{gender});
            $m->seasonGamesWon($$members{$member}{seasonGamesWon});
            $m->guildName($$members{$member}{guild});
            $m->class($$members{$member}{class});
            push @members, $m;
        }
        $t->members(\@members);
    }
    
    $self->get_heroic_access();
}

sub search_guild {
    my ( $self, $params ) = @_;

    my $xml = "guild-info.xml";

    croak "you need to specify a guild name" unless defined $$params{ guild };
    croak "you need to specify a realm"      unless defined $$params{ realm };
    croak "you need to specify a country name"
        unless defined $$params{ country };

    $self->fetch_data(
        {   xml     => $xml,
            realm   => $$params{ realm },
            name    => $$params{ guild },
            country => $$params{ country }
        }
    );

    $self->guild( Games::WoW::Armory::Guild->new );
    my $guild = $self->{ data }{ guildInfo }{ guild };
    my $members
        = $self->{ data }{ guildInfo }{ guild }{ members }{ character };

    $self->guild->name( $$guild{ name } );
    $self->guild->battleGroup( $$guild{ battleGroup } );
    $self->guild->realm( $$guild{ realm } );

    my @members;
    foreach my $member ( keys %{ $members } ) {
        my $m = Games::WoW::Armory::Character->new;
        $m->name( $member );
        $m->level( $$members{ $member }{ level } );
        $m->race( $$members{ $member }{ race } );
        $m->class( $$members{ $member }{ class } );
        $m->rank( $$members{ $member }{ rank } );
        $m->gender( $$members{ $member }{ gender } );
        push @members, $m;
    }
    $self->guild->members( \@members );
}

sub search_team {
    my ( $self, $params ) = @_;

    my $xml = "team-info.xml";
    croak "you need to specify a team name" unless defined $$params{ team };
    croak "you need to specify a country name"
        unless defined $$params{ country };
    croak "you need to specify a team style" unless defined $$params{ ts };
    croak "you need to specify a battlegroup name"
        unless defined $$params{ battlegroup };

    $self->fetch_data(
        {   xml         => $xml,
            team        => $$params{ team },
            battlegroup => $$params{ battlegroup },
            ts          => $$params{ ts },
            country     => $$params{ country }
        }
    );

    my $arena_team = $self->{ data }{ teamInfo }{ arenaTeam };
    my $members
        = $self->{ data }{ teamInfo }{ arenaTeam }{ members }{ character };

    $self->team( Games::WoW::Armory::Team->new() );
    $self->team->seasonGamesPlayed( $$arena_team{ seasonGamesPlayed } );
    $self->team->rating( $$arena_team{ rating } );
    $self->team->size( $$arena_team{ size } );
    $self->team->battleGroup( $$arena_team{ battleGroup } );
    $self->team->realm( $$arena_team{ realm } );
    $self->team->lastSeasonRanking( $$arena_team{ lastSeasonRanking } );
    $self->team->factionId( $$arena_team{ factionId } );
    $self->team->ranking( $$arena_team{ ranking } );
    $self->team->name( $$arena_team{ name } );
    $self->team->relevance( $$arena_team{ relevance } );
    $self->team->seasonGamesWon( $$arena_team{ seasonGamesWon } );

    my @members;
    foreach my $member ( keys %{ $members } ) {
        my $m = Games::WoW::Armory::Character->new;
        $m->name( $member );
        $m->class( $$members{ $member }{ class } );
        $m->realm( $$members{ $member }{ realm } );
        $m->battleGroup( $$members{ $member }{ battleGroup } );
        $m->race( $$members{ $member }{ race } );
        $m->gender( $$members{ $member }{ gender } );
        $m->guildName( $$members{ $member }{ guild } );
        push @members, $m;
    }
    $self->team->members( \@members );
}

sub get_heroic_access {
    my $self = shift;

    my @heroic_array;
    foreach my $rep ( keys %{ $self->character->reputation } ) {
        foreach my $fac ( keys %{ $self->character->reputation->{ $rep } } ) {
            foreach my $city (
                keys %{ $self->character->reputation->{ $rep }{ $fac }{ 'faction' } } )
            {
                foreach my $r ( keys %{ $HEROIC_REPUTATIONS } ) {
                    if (   $r eq $city
                        && $self->character->reputation->{ $rep }{ $fac }{ 'faction' }
                        { $city }{ 'reputation' } >= 21000 )
                    {
                        push @heroic_array, $$HEROIC_REPUTATIONS{ $r };
                    }
                }
            }
        }
    }
    $self->character->heroic_access( \@heroic_array );
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

package Games::WoW::Armory::Team;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw(seasonGamesPlayed rating size battleGroup realm lastSeasonRanking factionId ranking name relevance seasonGamesWon members)
);

1;

package Games::WoW::Armory::Guild;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(realm name battleGroup members) );

1;

package Games::WoW::Armory::Character;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw(name guildName arenaTeams battleGroup realm race gender faction level lastModified title class rank teamRank seasonGamesPlayed seasonGamesWon heroic_access characterinfo skill reputation)
);

1;

__END__
