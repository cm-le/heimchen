#!/usr/bin/perl

use DBI;
use utf8;
use File::Slurp;
use Data::Dumper;
use HTML::Entities;
use Spreadsheet::XLSX; # DON't USE converter

$dbh = DBI->connect("dbi:Pg:dbname=heimchen_dev;host=127.0.0.1", 
										"heimchen", "heimchen", 
										{PrintError => 1, AutoCommit => 0, pg_enable_utf8 => 1}) or die "no db";

$dbh->do("delete from imagetags") or die;
$dbh->do("delete from images") or die;
$dbh->do("delete from item_keywords") or die;
$dbh->do("delete from items") or die;
$dbh->do("delete from people_keywords") or die;
$dbh->do("delete from places_keywords") or die;
$dbh->do("delete from places_items") or die;
$dbh->do("delete from places_people") or die;
$dbh->do("delete from people") or die;
$dbh->do("delete from places") or die;


my %people=();
sub year {
		my $y = shift;
		$y = $y + 1900 if $y < 100;
		return $y;
}
sub get_date {
		my $s = shift;
		if ($s =~ /^ *(\d+) *$/) {
				my $y = year($1);
				return 1, "$y-01-01";
		}
		if ($s =~ /^ *(\d+) *\. *(\d+) *$/) {
				my $y = year($2);
				return 2, "$y-$1-01";
		}
		if ($s =~ /^ *(\d+) *\. *(\d+) *\. *(\d+) *$/) {
				my $y = year($3);
				return 3, "$y-$2-$1";
		}
		if ($s =~ /[^ ]/) {
				print STDERR "WARNUNG: Datum $s wird als undefiniert interpretiert\n";
		}
		return 0, undef;
}

open L, "hkslist.txt";
while (<L>) {
		chomp;
		$files{$_}=1;
}


my $pexcel = Spreadsheet::XLSX -> new ('personen.xlsx');
my $psheet =  (@{$pexcel -> {Worksheet}})[0];
foreach my $row (1 .. $psheet -> {MaxRow}) {
		my ($name, $gender, $comment, $born, $comment2, 
				$a1, $a1comment, $a2, $a2comment, $a3, $a3comment) = 
						map{ $psheet -> {Cells} [$row] [$_] -> {Val}} (0..10);
		next unless $name;
		my $maidenname;
		$name =~ s/^ +//;
		$name =~ s/ +$//;
		my $fullname = $name;
		if ($fullname =~ /\((.*)\)/) {
				$maidenname = $1;
				$fullname =~ s/ *\(.*\) *//;
				$maidenname =~ s/ *- *$//;
		}
		my ($lastname,$firstname)= split / *, */, $fullname;
		$firstname = "" if $firstname eq ". . .";
		$lastname =~ s/ *- */-/;
		my ($b, $d)=split / *- */, $born;
		my ($born_precision, $born_on)=get_date($b);
		my ($died_precision, $died_on)=get_date($d);
		my $id = $dbh->selectrow_array
				("insert into people(firstname, lastname, maidenname, gender, born_on, " .
				 " born_precision, died_on, died_precision, comment, inserted_at, updated_at, user_id) " . 
				 " values(?,?,?,?,?,?,?,?,?, current_timestamp, current_timestamp, 1) returning id", undef,
				 $firstname, $lastname, $maidenname, $gender, $born_on, $born_precision,
				 $died_on, $died_precision, (join " ", $comment, $comment2)) or die;
		$people{$name} = [$id];
		$people{$a1} = [$id, $a1comment] if $a1;
		$people{$a2} = [$id, $a2comment] if $a2;
		$people{$a3} = [$id, $a3comment] if $a3;		
}



my $excel = Spreadsheet::XLSX -> new ('fm.xlsx');
my $sheet =  (@{$excel -> {Worksheet}})[0];

# header ->  colnr
my %colnr = ();
foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
		$colnr{$col} = $sheet -> {Cells} [0] [$col] -> {Val};
}
# actual data

sub keyword_id {
		my $folder = shift;
		if (!$keywords{$folder}) {
				$keywords{$folder} = $dbh->selectrow_array
						("insert into keywords(category, name, for_photo_item, user_id, inserted_at, updated_at) " .
						 " values('Ordner', ?, true, 1, current_timestamp, current_timestamp) returning id", 
						 undef, $folder);
		}
		$keywords{$folder}
}

sub get_file {
		my ($pfolder, $pfile, $internal) = @_;
		$pfolder =~ s/Bilder ab Digi_Kamera/Bilder ab Digi-Kamera/;
		if ($pfolder eq "Film 54" and $pfile eq "Bi. 001.jpg") {
				$pfile = "Bi.001.jpg";
		}
		if ($pfolder eq "Film 40" and $pfile eq "Bild 15.jpg") {
				$pfile = "Film 40 Bild 15.jpg";
		}
		if ($pfolder eq "Film 40" and $pfile eq "Bild 14.jpg") {
				$pfile = "Film 40 Bild 14.jpg";
		}
		if ($pfolder eq "Film 40" and $pfile eq "Bild 13.jpg") {
				$pfile = "Film 40 Bild 13.jpg";
		}

		my $filename = $pfile;
		my $folder   = $pfolder;
		my $real_file = "./" . $folder . "/" . $filename;

		$filename =~ s/Film +/Film/;
		$filename =~ s/Bild +/Bild/;
		$filename =~ s/Bi\. +/Bild/;
		return keyword_id($folder), $filename, ($files{$real_file} ? $real_file : undef);
}

sub create_place {
		my ($image_id, $address, $building, $comment)= @_;
		my $place_id = $ID{join ("::", "place", "address", "building")};
		if ($id) {
				if ($comment) {
						$dbh->do("update places set comment=concat_ws(' ', ?, comment) where id=?", undef,
										 $comment, $id);
				}
				return $id;
		}
		if (!$place_id) {
				my $housenr;
				$address =~ s/str\./strasse /;
				if ($address =~ / +(\d+.*)/) {
						$housenr = $1;
						$address =~ s/ +(\d+.*)//;
				}
				$place_id = 
						$dbh->selectrow_array
						("insert into places(city, address, housenr, " . 
						 " building, comment, user_id, inserted_at, updated_at) " . 
						 " values('Seuzach', ?, ?, ?, 1, current_timestamp, current_timestamp) returning id",
						 undef, $address, $housenr, $building, $comment);
		}
		if (!$ID_PLACE{$image_id . "::" . $place_id}) {
				$ID_PLACE{$image_id . "::" . $place_id} = 
						$dbh->do("insert into imagetags(image_id, place_id, user_id, inserted_at, updated_at) " .
										 " values(?,?,1, current_timestamp, current_timestamp)", undef,
										 $image_id, $id);
		}
}


sub handle_strings {
		my ($item_id, $image_id, $s)=@_;
		my %std = (
				'Foto s/w' => [0,'keyword', 'Technik', 'Foto s/w'],
				'Dia' =>      [0,'keyword', 'Technik', 'Dia'],
				'Digital-Foto' => [0,'keyword', 'Technik', 'Digital-Foto'],
				'Foto farbig' => [0,'keyword', 'Technik', 'Foto farbig'],
				'Foto s/w koloriert' => [0,'keyword', 'Technik', 'Foto s/w koloriert'],
				'Glas-Dia 10 x 8.5 cm' => [0,'keyword', 'Technik', 'Glas-Dia 10 x 8.5 cm'],
				'Postkarte' => [0, 'keyword', 'Technik', 'Postkarte'],
				'Postkarte „Gruss aus Seuzach mit Herzlichem Glückwunsch“ farbig koloriert' =>
				[1, 'keyword', 'Technik', 'Postkarte'],
				'Festplatz Rietacker, Festzelt' => [1,'place', 'Festplatz Rietacker'],
				'Ausblick vor der Überbauung Obstgarten' => [1,'place', 'Gebiet Obstgarten'],
				'Bahnhof Seuzach' => [0,'place', 'Bahnhof Seuzach'],
				'Schülerzeichnungen als Bauabschrankungen beim Bau des Zentrum „Chrebsbach“' => 
				[1, 'place', 'Chrebsbach'],
				'Rösslipark beim Chrebsbach' => [1, 'place', 'Chrebsbach'],
				'Birchstr. bei Einmündung Austr. mit Blick Richtung Nordwesten' => [1, 'place', 'Birchstrasse'],
				'Bahnhof Seuzach ohne jeden An- und Umbau' => [1, 'place', 'Bahnhof Seuzach'],				
				'Äusserer Bahnübergang (2.Bahnübergang östlich nach Station) vor der Schliessung' =>
				[1,'place','Äusserer Bahnübergang (2.Bahnübergang östlich nach Station)'],
				'Stationsstr.' => [0,'place', 'Stationsstrasse'],
				'Schweizermeisterschaften im Wettpflügen auf dem Heimenstein' =>
				[1,'place', 'Heimenstein'],
				'Bahnübergang Stationsstr.' => [0,'place', 'Bahnübergang Stationsstr.'],
				'Gebiet Obstgarten' => [0,'place', 'Gebiet Obstgarten'],
				'Oberohringen' => [0,'place', 'Oberohringen'],
				'Birchstr.' => [0, 'place', 'Birchstrasse'],
				'Rest. Bernergüetli' => [0, 'place', 'Rest. Bernergüetli'],
				'Seuzemer - Märt vor dem alten Sek. Schulhaus' => [1, 'place', 'Altes Sek. Schulhaus'],
				'Stationsstrasse' => [0, 'place', 'Stationsstrasse'],
				'Stadlerstr.' => [0, 'place', 'Stadlerstrasse'],
				'Strehlgasse' => [0, 'place', 'Strehlgasse'],
				'Amelenberg' => [0, 'place', 'Amelenberg'],
				'Bahnübergang nach Reutlingen' => [0, 'place', 'Bahnübergang nach Reutlingen'],
				'auf dem Heimenstein' => [1, 'place', 'Heimenstein'],
				'Entenweiher' => [1, 'place', 'Weiher'],
				'25-Jahre Musikgesellschaft Seuzach; Empfang der Gastvereine am Bahnhof durch die Musikgesellschaft' =>
				[1, 'place', 'Bahnhof'],
				'Kirchgasse' => [0, 'place', 'Kirchgasse'],
				'Festplatz Rietacker' => [0, 'place', 'Festplatz Rietacker'],
				'Kirche Seuzach' => [0, 'place', 'Kirche Seuzach'],
				'Abbruch alter Bahnhof Seuzach' => [1, 'place', 'Bahnhof'],
				'Kirchhügel, Kirche und Pfarrhaus' => [1, 'place', 'Kirche Seuzach'],
				'im Weiher' => [1, 'place', 'Weiher'],
				'Weiher' => [1, 'place', 'Weiher'],
				'Stationsstrasse, Metzgerei Friederich', => [0, 'place', 'Stationsstrasse', 'Metzgerei Friederich'],
				'Haus Strehlgasse 5 (5 = unsicher)' => [1, 'place', 'Strehlgasse'],
				'Winterthurerstr.' => [0, 'place', 'Winterthurerstrasse'],
				'Schwimmbad Seuzach' => 'P',
				'Schulhaus Rietacker' => 'P',
				'Haus Därendinger (Untervogthaus; Kellerhaus) Oberohringen,' => [0, 'place', 'Haus Därendinger, Oberohringen'],
				'Breitestr.' => 'P',
				'Hettlingen' => 'P',
				'Bahnhof'  => 'P',
				'Kreuzung Dorf' => 'P',
				'Dorfeingang Winterthurerstr. Richtung Dorf' => 'P',
				'Stationsstr. mit Bahnhof (rechter Bildrand), Haus Dornbirer (linker Bildrand) und Haus Schmid (Bildmitte) sind im Bau' => [1, 'place', 'Bahnhof Seuzach'],
				'Bauernhaus Meier, Walter' => 'P',
				'Hptm. Keller-Haus Ober-Ohringen; Detail Dachuntersicht mit geschnitzten„Dachrafen“' =>
				[0, 'place', 'Hptm. Keller-Haus (heue Derendinger) Ober-Ohringen'],
				'Hptm. Keller-Haus (heue Derendinger) Ober-Ohringen' => 'P', 
				'Heimensteinstr. Richtung Dorf' => [1, 'place', 'Heimensteinstrasse'],
				'Kirchhügel mir Kirche und Pfarrhaus; Blick von Winterthurerstr.' =>
				[1, 'place', 'Kirche Seuzach'],
				'Umzug 700-Jahrfeier, Bauer (Ernst Schwarz sen.) mit Säsack auf der Birchstr.' =>
				[1, 'place', 'Birchstrasse'],
				'Haldenstrasse' => 'P',
				'Winterthurerstr., Riegelhaus Ackeret' => [1, 'place', 'Winterthurerstrasse'],
				'Arena Schulhaus Halden' => [1, 'place', 'Schulhaus Halden'],
				'Coop Seuzach Strehlgasse, Bäckerei-Waren-Verkauf mit Bedienung' => [1, 'place', 'Strehlgasse'],
				'Kanalisations-Anschluss Haus Schmid - Därendinger Trottenstr.' => [1, 'place', 'Trottenstrasse'],
				'Klassenfoto mit Lehrer beim hinteren Kircheneingang/Treppe' => [1, 'place', 'Kirche Seuzach'],
				'Strasse über den Amelenberg' => 'P',
				'Bahnhof Seuzach mit Stellwerk und Dampf-Zug, Bahnhofvorstand, Kondukteur und weiteren Bahnangestellten' =>
				[1, 'place', 'Bahnhof Seuzach'],
				'Winterthurerstr. mit Migros und Haus Bianchi' => [1, 'place', 'Winterthurerstrasse'],
				'Blick vom Friedhof-Kiesplatz' => [1, 'place', 'Friedhof-Kiesplatz'],
				'Mähdrescher im Weiher gesteuert von Walter Meier im Weiher' => [1, 'place', 'Weiher'],
				'Winterthurerstr. Dorfauswärts Richtung Süden' => [1, 'place', 'Winterthurerstrasse'],
				'Garage Frauenfelder (später: Vetterli, heute Engler - Vetterli) Stationsstr.' =>
				[1, 'place', 'Stationsstrasse'],
				'Blick auf den Heimenstein (von Turnerstr. aus)' => [1, 'place', 'Heimenstein'],
				'Bahnhof Seuzach mit Dampf-Zug und Rest. Bahnhof' => [1, 'place', 'Bahnhof Seuzach'],
				'Weiherstr. Blick Richtung Ausserdorf (aus Fenster 1.Stock, Leberenstr.)' => [1, 'place', 'Weiherstrasse'],
				'Schwimmbad Seuzach, kurz nach Eröffnung' => [1, 'place', 'Schwimmbad Seuzach'],
				'horizontal über ganzes Bild Bachtobelstr.' => [1, 'place', 'Bachtobelstrasse'],
				'Beatusheim (früher Bauernhaus Schwarz)' => 'P',
				'Stationsstr. mit Einmündung Mörsburgstr. mit ehem. Postgebäude' => [1, 'place', 'Stationsstrasse'],
				'Grosse Trotte am Heimenstein Seuzach (bewohnt von Frl. Mayor und Hr. Cuony)' => [1, 'place', 'Heimenstein'],
				'Schwarz, Edi mit Passagier Demuth, Walter mit Motorboot auf dem Weiher' => [1, 'place', 'Weiher'],
				'Bahnhof Seuzach mit Rest. Bahnhof' => [1, 'place', 'Bahnhof Seuzach'],
				'Zeitungsartikel über Bahnhof Reutlingen mit Bild' => [1, 'place', 'Bahnhof Reutlingen'],
				'Elektrifizierungs-Feier der Bahnlinie nach Ezwilen auf dem Bahnhof Seuzach, mit viel Festvolk' =>
				[1, 'place', 'Bahnhof Seuzach'],
				'Kirchhügel' => [1, 'place','Kirche Seuzach'],
				'Umzug 700-Jahrfeier, Bauern mit Kühen auf der Birchstr.' => [1, 'place', 'Birchstrasse'],
				'Rest. Bernergüetli mit Saalanbau (linke Fotoseite); Blick auf Gartenwirtschaft südlich des Hauses' =>
				[1, 'place', 'Rest. Bernergüetli'],
				'Winterthurerstr., Haus Bianchi' => 'P',
				'Bahnhof Seuzach und Rest. Bahnhof' => [1, 'place', 'Bahnhof Seuzach'],
				'Bachtobelstr.' => [0, 'place', 'Bachtobelstrasse'],
				'Weiherstrasse' => 'P',
				'Kreisel Dorf' => 'P',
				'Strehlgasse Richtung Welsikonerstr.' => [1, 'place', 'Strehlgasse'],
				'Autobahn / Amelenberg' => [1, 'place', 'Autobahn'],
				'Strehlgasse 16' => [1, 'place', 'Strehlgasse'],
				'Heimenstein' => 'P',
				'Welsikonerstr. / Einmündung Strehlgasse' => [1, 'place', 'Welsikonerstrasse'],
				'Weiherstr.' => [0, 'place', 'Weiherstrasse'],
				'Einmündung Kirchgasse in Winterthurerstr.' => [1, 'place', 'Kirchgasse'],
				'Waldschneise für die Autobahn mit gefällten Bäumen im Herbst 1963' => [1, 'place', 'Autobahn'],
				'Haus Julius Steinmann Unter-Ohringen' => 'P',
				'Haus Bianchi mit Luftschiff „Graf Zeppelin“ (Fotomontage)' => [1, 'place', 'Winterthurerstr., Haus Bianchi'],
				'Inneres der Kirche Seuzach, Kanzel, Pfarrstuhl, Chorgestühl und Bank unter der Kanzel' =>
				[1, 'place', 'Kirche Seuzach'],
				'Ohringerstr., Schulhaus Rietacker' => [1, 'place', 'Schulhaus Rietacker'],
				'Weiher im Winter' => [1, 'place', 'Weiher'],
				'Haus Müller; Eingangs Kirchgasse links' => [1, 'place', 'Kirchgasse'],
				'Lagerplatz Gärtnerei Gehring neben Kehrplatz Mörsburgstr' => [1, 'place', 'Mörsburgstrasse'],
				'Mercerie Ott, Stationsstr.' => [1, 'place', 'Stationsstrasse'],
				'Dampfloki bei der Abfahrt aus Bahnhof Richtung Welsikon mit viel Rauch' =>
				[1, 'place', 'Bahnhof Seuzach'],
				'Metzgerei Elias Greuter Stationsstr. vor der Metzgerei 2 Jäger mit erlegtem Wild an Stange (3 Rehe, 6 Füchse)' => [1, 'place', 'Stationsstrasse'],
				'Unter-Ohringen, Haus Ackeret' => [1, 'place', 'Unter-Ohringen'],
				'Welsikonerstr. Haus ehem. Rotzinger' => [1, 'place', 'Welsikonerstrasse'],
				'Autobahnbau; Bäume wurden für die Autobahnschneise gefällt' => [1, 'place', 'Autobahn'],
				'Neuapostolische Gemeinde im Kirchenraum an der Bachtobelstr. 18' => [1, 'place', 'Bachtobelstrasse'],
				'„alte Trotte“ Unter-Ohringen (heute abgerissen)' => [1, 'place', 'Unter-Ohringen'],
				'Alter Eingang zur Kirche Seuzach mit alter Emporen-Treppe' => [1, 'place', 'Kirche Seuzach'],
				'Weichenstellwerk Bahnhof Seuzach' => [1, 'place', 'Bahnhof Seuzach'],
				'Haus Baumeister Lutz (früher Kasimir Zirn), Stationsstr.' => [1, 'place', 'Stationsstrasse'],
				'Hptm. Keller-Haus Ober-Ohringen' => [1, 'place', 'Hptm. Keller-Haus (heue Derendinger) Ober-Ohringen'],
				'Stadlerstr. vor dem Ausbau mit Sicht auf den Bahnübergang' => [1, 'place', 'Stadlerstrasse'],
				'Einweihung Schulhaus Rietacker, Kinder-Aufführung des Struwelpeter' => [1, 'place', 'Schulhaus Rietacker'],
				'Grundstück für Sek. Schulhaus Halden' =>    [1, 'place', 'Schulhaus Halden'],
			  'im Hintergrund Stationsstr., Häuser' => [1, 'place', 'Stationsstrasse'],
				'Baugespann des Kindergarten Bachtobelstr. 17; im Vordergrund: Lotti Rüesch mit Kinderwagen;' =>
				[1, 'place', 'Kindergarten Bachtobelstrasse'],
				'Hptm. Keller-Haus Ober-Ohringen; Hauseingang' => 
				[1, 'place', 'Hptm. Keller-Haus (heue Derendinger) Ober-Ohringen'],
				'Teppichweberei Fehr Bachtobelstr. (Anbau / Vergrösserung) durch Zimmermann Diener, Jakob' =>
				[1, 'place', 'Bachtobelstrasse'],
				'Kreuzung Dorf (vor Bau des Kreisels), (rechter Bildrand: Ausfahrt vom Migros)' => 
				[1, 'place', 'Kreisel Dorf'],
				'Schwimmbad Seuzach; Sonntagmorgen: Der Badmeister Albert Rüeger bedient die Wasser-Fontäne' =>
				[1, 'place', 'Schwimmbad Seuzach'],
				'Glockenaufzug, Cortège; Glockenwagen biegt in Kirchgasse ein' => [1, 'place', 'Kirchgasse'],
				'Stationsstr., Gärtnerei Niederer' => [1, 'place', 'Stationsstrasse'],
				'Läutwerk Bahnhof Seuzach' =>  [1, 'place', 'Bahnhof Seuzach'],
				'Kirchbühl' => 'P',
				'Ährenpuppen werden auf Wagen mit Hürlimann-Traktor geladen am Kirchbühl (Chilehölzli)' =>
				[1, 'place', 'Kirchbühl'],
				'Schwimmbad' => [0, 'place', 'Schwimmbad Seuzach'],
				'Kirche Seuzach, alter Stich' => [1, 'place', 'Kirche Seuzach'],
				'Baumschule, Heimenstein („Heuteeri“)  mit Welsikonerstr. und Weiherbächli' => [1, 'place', 'Heimenstein'],
				'25-Jahr Jubiläum Musikgesellschaft Seuzach; Empang der Gastvereine am Bahnhof Seuzach durch den Musikverein Seuzach' => [1, 'place', 'Bahnhof Seuzach'],
				'Birchstrasse' => 'P',
				'Unterohringen, Kläranlage' => [1, 'place', 'Unter-Ohringen'],
				'Kirchhügel, Kirche, Pfarrhaus' => [1, 'place', 'Kirche Seuzach'],
				'Breitestrasse' => 'P',
				'Kirchgasse, Wagnerei Müller' => [1, 'place', 'Kirchgasse'],
				'Haus Därendinger (Untervogthaus; Kellerhaus) Oberohringen, von aussen mit Haustüre' =>
				[1, 'place', 'Hptm. Keller-Haus (heue Derendinger) Ober-Ohringen'],
				'Autobahn-Eröffnung' => [1, 'place', 'Autobahn'],
				'Haus Bianchi, Winterthurerstr.' => [1, 'place', 'Winterthurerstr., Haus Bianchi'],
				'Autobahnbau; das Lehrgerüst für die Autobahn über die Töss stürzt kurz vor Arbeitsbeginn ein' =>
				[1, 'place', 'Autobahn'],
				'Kran räumt zusammengebrochenes Lehrgerüst der Autobahnbrücke im Hard (Wülflingen/Töss) auf' =>
				[1, 'place', 'Autobahn'],
				'Untervogthaus Keller dann Derendinger' =>
				[1, 'place', 'Hptm. Keller-Haus (heue Derendinger) Ober-Ohringen'],
				'Milchzentrale Seuzach' => 'P',
				'Schwimmbad Seuzach von der Welsikonerstr. aus (Postkarte von O. Wohlgensinger)' =>
				[1, 'place', 'Schwimmbad Seuzach'],
				'Autobahn-Eröffnung; Koni Meier fährt mit Ross und Wagen (beladen mit Emmentaler-Käseleiben) zur Autobahn-Eröffnung' => [1, 'place', 'Autobahn']);
		foreach my $e (split / *[\n\r]+ */, $s) {
				my $std = $std{$e};
				if ($std) {
						if ($std eq 'P') {
								$std = [0, 'place', $e];
						}
						my ($keep, $which, @params) = @{$std};
						if ($which eq "place") {
								create_place($image_id, $params[0], "")
						} else {
								my $id = $ID{join ("::", $which, @params)};
								if (!$id) {
										$id = $ID{join ("::", $which, @params)} =
												$dbh->selectrow_array
												("insert into keywords(category, name, user_id, inserted_at, updated_at) " . 
												 " values(?, ?, 1, current_timestamp, current_timestamp) returning id",
												 undef, $params[0], $params[1]);
								}
								if (!$ID_KEYWORD{$item_id  . "::" . $id}) {
										$ID_KEYWORD{$item_id  . "::" . $id} = 
												$dbh->do("insert into item_keywords(item_id, keyword_id, user_id, inserted_at, updated_at) " .
																 " values(?,?,1, current_timestamp, current_timestamp)", undef,
																 $item_id, $id);
								}
				}
				}
		}
}


my %items;
foreach my $row (1 .. $sheet -> {MaxRow}) {
		my %r;
		foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
				$r{$colnr{$col}} = decode_entities($sheet -> {Cells} [$row] [$col] -> {Val});
		}

		# 'A_Datei' -> ignorieren

		push @strings, split / *[\n\r]+ */, $r{'Aa_Hauptfeld'};
		push @strings, split / *[\n\r]+ */, $r{'Inh_Inhalt'};
		
		if (!$items{$r{'Aa_Hauptfeld'}}) { # item neu anlegen
## 				$items{$r{'Aa_Hauptfeld'}} = $dbh->selectrow_array
				## 						("insert into items.... returning id");
				$items{$r{'Aa_Hauptfeld'}} = 1;
		}
		my $item_id=$items{$r{'Aa_Hauptfeld'}};
		
		# Bild anlegen

		my ($keyword, $filename, $real_file) = 
				get_file($r{'Pfad_Verzeichnis_01'}, $r{'Dateiname'}, $r{'Pfad_Ausgabe_Syst_URL_Kl_beschriftete'});
		if (!$real_file) {
				print STDERR "WARNING: NO FILE " . $r{'Pfad_Verzeichnis_01'} . "/" . $r{'Dateiname'} . "\n";
		} else {
				my $type = ($filename =~ /jpe?g$/i) ? "jpg" : "tif";
				my @ry = (2010,2011,2012,2013,2014,2015,2016);
				my @rm = (1,2,3,4,5,6,7,8,9,10,11,12);
				my $y = $ry[rand @ry] ; my $m = $rm[rand @rm] ;
				my $ts = "$y-$m-01 12:00:01";
				my ($image_id) =
						$dbh->selectrow_array("insert into images(original_filename, user_id, inserted_at, updated_at) " . 
																	" values(?,1,?, ?) returning id", 
																	undef, $filename, $ts, $ts) or die;

				my $path_name = "$y/$m/$image_id";
				
				$tocopy{$real_file} = $path_name . "/orig.$type";


				## Places as listes in the topographic fields
				foreach (1,2,3,4) {
						my $prefix = $r{"Top_Präfix $_"};

						my $topo   = $r{"Top_topogr Bez $_"};
						my $building = $r{"Top_Gebäude $_"};
						my $comment = $r{"Top_Suffix $_"};
						$comment = "$prefix $comment";
						
						if ($topo || $building) {
								if ($building && !$topo) {
										$topo = $building;
										$building = "";
								}
								create_place($image_id, $topo, $building, $comment);
						}
				}

				## PEOPLE

				
						
				my $name = $r{'Aa_Hauptfeld'};
				handle_strings($item_id, $image_id, $r{'Aa_Hauptfeld'});
				my $comment  = handle_strings($item_id, $image_id, $r{'Aa_Hauptfeld'} . "\n" . $r{'Inh_Inhalt'});
				
				# TODO item_keywords anlegen!!!!
		}				
}

my %count;
foreach (@strings) {
		$count{$_}++;
}
foreach $s (sort {$count{$b} <=> $count{$a}} (keys %count)) {
		print "Key: $s -> $count{$s}\n";
}

__END__
				
		# 'Aa_Hauptfeld' -> name von wird zu item+image, gleiche hauptfelder werden werden gleichem item zugeordnet
		# 'Dateiname' -> wird entsprechend gesucht
		# 'Inh_Inhalt' -> zusammen mit Inh_Text zu Kommentar
		# 'Inh_Text' -> s.o.
		# 'Sach_Obj Techn' -> wird zu stichwort mit Kategorie "Technik"
		48  'Dat_Art 1'
49  'Dat_Approx. 1'
50  'Dat_Tag 1'
51  'Dat_Monat 1'
52  'Dat_Jahr manuell 1'
53  'Dat_Präfix 1'
54  'Dat_Jh 1'
55  'Dat_Suffix 1'
56  'Dat_vnChr 1'
57  'Dat_Jahr 1'
58  'Dat_Zeitraum Verkn a'
59  'Dat_Art 2'
60  'Dat_Approx. 2'
61  'Dat_Tag 2'
62  'Dat_Monat 2'
63  'Dat_Jahr manuell 2'
64  'Dat_Präfix 2'
65  'Dat_Jh 2'
66  'Dat_Suffix 2'
67  'Dat_vnChr 2'
68  'Dat_Jahr 2'
69  'Pers_A Präfix 1'
70  'Pers_A Name Vn 1'
71  'Pers_A Hauptfunktion 1'
72  'Pers_A Lebensdaten 1'
73  'Pers_A Funktion 1'
74  'Pers_A Suffix 1'
75  'Pers_A Präfix 2'
76  'Pers_A Name Vn 2'
77  'Pers_A Hauptfunktion 2'
78  'Pers_A Lebensdaten 2'
79  'Pers_A Funktion 2'
80  'Pers_A Suffix 2'
81  'Pers_A Präfix 3'
82  'Pers_A Name Vn 3'
83  'Pers_A Hauptfunktion 3'
84  'Pers_A Lebensdaten 3'
85  'Pers_A Funktion 3'
86  'Pers_A Suffix 3'
87  'Präs_Abteilung'
88  'Pers_A Präfix 4'
89  'Pers_A Name Vn 4'
90  'Pers_A Hauptfunktion 4'
91  'Pers_A Lebensdaten 4'
92  'Pers_A Funktion 4'
93  'Pers_A Suffix 4'
94  'Top_Art 1'
95  'Top_Präfix 1'
96  'Top_topogr Bez 1'
97  'Top_Gebäude 1'
98  'Top_Suffix 1'
99  'Top_Art 2'
100  'Top_Präfix 2'
101  'Top_topogr Bez 2'
102  'Top_Gebäude 2'
103  'Top_Suffix 2'
104  'Top_Art 3'
105  'Top_Präfix 3'
106  'Top_topogr Bez 3'
107  'Top_Gebäude 3'
108  'Top_Suffix 3'
109  'Top_Art 4'
110  'Top_Präfix 4'
111  'Top_topogr Bez 4'
112  'Top_Gebäude 4'
113  'Top_Suffix 4'
114  'Pfad_Ausgabe_Syst_URL_Kl_beschriftete'
115  'Pers_Präfix Ikon'
116  'Pers_Nam Vn Funk Ldaten Ikon'
117  'Pers_Funktion Ikon'
118  'Pers_Suffix Ikon'
119  'Thes_Hauptfeld'
		
