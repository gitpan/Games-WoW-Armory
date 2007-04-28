#!/usr/bin/perl -w

use strict;
use lib ('../lib');
use Getopt::Simple qw($switch);
use Games::WoW::Armory;

my ( $options ) = {
    help => { type    => '',
              env     => '-',
              default => '',
              verbose => 'this help',
              order   => 1,
    },
    character => { type    => '=s',
                   env     => '-',
                   default => '',
                   verbose => 'character name',
                   order   => 2,
    },
    guild => { type    => '=s',
               env     => '-',
               default => '',
               verbose => 'guild name',
               order   => 3,
    },
    realm => {
        type    => '=s',
        env     => '-',
        default => '',
        verbose => 'realm name',
        order   => 4,

    },
    country => {
        type    => '=s',
        env     => '-',
        default => '',
        verbose => 'Region name (EU|US)',
        order   => 5,

    },
};

my $o = Getopt::Simple->new();
if ( !$o->getOptions( $options, "Usage : $0 [options]" ) ) {
    exit( -1 );
}

my $armory = Games::WoW::Armory->new();

if ( !defined $$switch{ 'realm' } ) {
    die "you have to give a realm name";
}

if ( !defined $$switch{ 'country' } ) {
    die "you have to give a country name (EU|US)";
}

if ( $$switch{ 'character' } && $$switch{ 'guild' } ) {
    die "please, specify only a character name OR a guild name";
}

if ( $$switch{ 'character' } ) {
    search_character();
} else {
    search_guild();
}

sub search_guild {
    $armory->search_guild( { realm   => $$switch{ 'realm' },
                             guild   => $$switch{ 'guild' },
                             country => $$switch{ 'country' } } );
    foreach my $member ( keys %{ $armory->members } ) {
        print "- " . $member . " ("
            . $armory->members->{ $member }{ class } . " "
            . $armory->members->{ $member }{ race }
            . ") lvl "
            . $armory->members->{ $member }{ level } . "\n";
    }
}

sub search_character {
    $armory->search_character( { realm     => $$switch{ 'realm' },
                                 character => $$switch{ 'character' },
                                 country   => $$switch{ 'country' } } );
    print "- "
        . $armory->character->{ name } . " ("
        . $armory->character->{ class } . " "
        . $armory->character->{ race } . ") "
        . $armory->character->{ level } . "\n";

    if (scalar @{$armory->heroic_access} == 0){
        print "No heroic access yet.\n";
    }else{
        print "\tHeroic Access:\n";
        foreach my $key (@{$armory->heroic_access}){
            print "Have access to the $key.\n";
        }
    }

}
