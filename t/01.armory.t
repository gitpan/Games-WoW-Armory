#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;
use Games::WoW::Armory;
use Data::Dumper;

use_ok('Games::WoW::Armory');
can_ok('Games::WoW::Armory', 'fetch_data');
can_ok('Games::WoW::Armory', 'search_character');
can_ok('Games::WoW::Armory', 'search_guild');

my $char = Games::WoW::Armory->new();
$char->search_character({realm => "Elune", character => "Aarnn", country => "EU"});
is ($char->character->{name}, "Aarnn", "Character name ok");
is ($char->character->name, "Aarnn", "New character name ok");
is ($char->character->level, 70, "New characterlevel ok");

my $guild = Games::WoW::Armory->new();
$guild->search_guild({realm => "Elune", guild => "Cercle+De+L+Anneau+Rond", country => "EU"});
is ($guild->guild->name, "Cercle De L Anneau Rond", "Guild name");
is ($guild->guild->realm, "Elune", "Realm name");
is ($guild->guild->battleGroup, "Cataclysme", "Battlegroup name");