#!/usr/bin/perl -w

use warnings;
use strict;
use File::Basename;
use File::Find;
use File::Spec;


my $path = '/';
my $serwer = '';
if($#ARGV == -1){
    print "Podaj argument: -h aby uzyskac informacje o programie, lub podaj ścieżkę do katalogu aby poprawnie uruchomić program\n"; exit;
}

if ($ARGV[0] eq "-h"){
    print "Program przeszukuje katalog i podkataliogi, podany w argumencie z konsoli. \nTworzy drzewo katalogow i zapisuje je do pliku output.html w tym samym katologu co odbywało się przeszukiwanie.
     \nNastepnie uruchamiany jest skrypt w Pythonie, ktory odczytuje wygenerowany plik html oraz dodaje do niego informacje o plikach oraz o znalezionych duplikatach. \n
Nastepnie, jesli komenda -s byla wpisana, uruchamiany jest skrypt w Bashu, ktory udostepnia te informacje na serwerze localhost na porcie 8888\n
Jesli wygenerowales juz plik z danymi, mozesz uzyc serwer.sh jako osobny program. \n\n Dostepne argumety programu: \n -h  : Pomoc \n lub \n ~/sciezka/do/katalogu \n lub \n Po sciezce do katalogu wpisz -s aby uruchomic serwer.\n";
    exit;
}
else {
    $path = $ARGV[0];
    $path = $1 if($path=~/(.*)\/$/);
}

unless (-d "$path") {
    print "Nieprawidlowa sciezka\n";
    exit;
}
if($#ARGV >= 1){
    if($ARGV[1] eq "-s"){
        $serwer = "-s";
    }
}
my $dirname = $path;
my $filename = "/output.html";
my $fullname = $dirname . $filename;
if ( -e $fullname ){
    print "Plik output.html już istnieje w podanej lokalizaji!\n";
    print "Czy chcesz nadpisac ten plik?: (t/n) [Domyslnie 't'] ";

    my $dec = <STDIN>;
    if ($dec eq "n\n" && $serwer eq "-s") {
        $dirname =  dirname(File::Spec->rel2abs(__FILE__));
        system("$dirname/serwer.sh $path");
        exit
    } elsif ($dec eq "n\n" ) {
        print "Nie mam nic do roboty\nKoncze prace\n";
        exit
    }
}
print "Czy chcesz wygenerować plik stylów?: (t/n) [Domyslnie 'n']\n";
my $decision = <STDIN>;
chomp $decision;

print "Czy chcesz odfiltrować wynik ze wzgledu na rozszerzenie pliku?: (t/n) [Domyslnie 'n']\n";
my $decision1 = <STDIN>;
chomp $decision1;

my $filtr = "";
my $unfiltr = "";
if ($decision1 eq "t") {
    START:
    print "1 - Wyszukaj tylko pliki o podanym rozszezeniu\n";
    print "2 - Wyszukaj wszystkie pliki o rozszezeniu innym niz podany\n";
    my $decision3 = <STDIN>;

    if ($decision3 == 1) {
        print "Podaj typ pliku jakiego szukasz (np: txt):";
        $filtr = <STDIN>;
        chomp $filtr;
    } elsif ($decision3 == 2) {
        print "Podaj typ pliku jaki chcesz odfiltorwac (np: txt): ";
        $unfiltr = <STDIN>;
        chomp $unfiltr;
    } else {
        print "Bledna opcja!\n";
        goto START;
    }

}
open OUTFILE, ">$dirname/output.html" || die "Can't open $dirname/output.html: $!\n";;
if ($decision eq "t") {
#    my $existingdir = "$dirname/css";
#    mkdir $existingdir unless -d $existingdir;
#    open OUTFILE, ">$dirname/css/style.css";

    print OUTFILE qq|<style>
p { color: #003896; font-family: 'Helvetica Neue', sans-serif; font-size: 20px; line-height: 24px; margin: 0 0 24px; text-align: justify; text-justify: inter-word; }
h1 { color: #111; font-family: 'Helvetica Neue', sans-serif; font-size: 25px; font-weight: bold; letter-spacing: -1px; line-height: 1; text-align: center; }
h2 { color: #111; font-family: 'Open Sans', sans-serif; font-size: 15px; font-weight: 300; line-height: 32px; margin: 0 0 72px; text-align: center; }
a { color:#000: ; background: #eff5ff; text-decoration: none; font-size: 18px; line-height: 150%;}
a:hover {text-decoration: underline; background: #FFF;}
a, a:visited, a:hover, a:active {color: inherit;}
table { background-color: #eff5ff; border-collapse: collapse; border-width: 2px; border-color: #000000; border-style: solid; color: #000000;}
table td, table th { border-width: 2px; border-color: #000000; border-style: solid; padding: 3px;}
table th {  background-color: #fff;}
</style>| . "\n";
}

print 'Generowanie drzewa katalogow';

print OUTFILE qq|
<html>
    <head>
        <title>$dirname</title>
        <meta charset="UTF-8">
        <base href="~/" />
        |;

if ($decision eq "t") {
    print OUTFILE qq|
        <link rel="stylesheet" href="css/style.css">| . "\n";
}

print OUTFILE qq|</head>
<body>| . "\n";

print OUTFILE qq|<h1>Katalog wyszukiwania: $dirname</h1> <br></br>| . "\n";

my $x = "/";
my $s = () = $dirname =~ /$x/g;

my $i = 0;
my @all_file_names;

find sub {
        return if -d;
        push @all_file_names, $File::Find::name;
    }, $dirname;

if ( $unfiltr ne "" ) {
    for $path (@all_file_names) {
        unless ($path =~ m/[.]$unfiltr$/) {
            $i++;
            my $c = () = $path =~ /$x/g;
            my $sub = $c - $s;
            my $tab = "";
            my $t = "&emsp;";
            for (my $n = 0; $n < $sub; $n++) {
                $tab = $tab . '' . $t;
            }
            print OUTFILE qq|$tab<a href="$path">$path</a> </br>| . "\n";
        }
    }
} else {
    for $path (@all_file_names) {
        if ($path =~ m/[.]$filtr$/ || $filtr eq "") {
            $i++;
            my $c = () = $path =~ /$x/g;
            my $sub = $c - $s;
            my $tab = "";
            my $t = "&emsp;";
            for (my $n = 0; $n < $sub; $n++) {
                $tab = $tab . '' . $t;
            }
            print OUTFILE qq|$tab<a href="$path">$path</a> </br>| . "\n";
        }
    }
    print OUTFILE qq|<br><p>Znaleziono $i plików $filtr</p></br>| . "\n";
    print OUTFILE qq|</body>
</html>|;
}

$dirname =  dirname(File::Spec->rel2abs(__FILE__));
system("$dirname/statystyka.py $path $filtr $serwer");


