#!/usr/bin/perl

# Utility to see the origin and quantity of spots per day.
#
# To be copied to /spider/local_cmd/
#
# From the command line: ./spots_node.pl <day>.dat
#
# Created by Kin EA3CV
#
# 20231228 v0.0
#

use strict;
use warnings;
use File::Spec;
use POSIX qw(strftime);

# Obtener el año actual
my $current_year = strftime "%Y", localtime;

# Ruta fija con el año actual
my $fixed_path = "/spider/local_data/spots/$current_year";

# Comprobar que se ha proporcionado un nombre de fichero
if (@ARGV != 1) {
    die "Uso: $0 nombre_del_fichero\n";
}

# Nombre del fichero proporcionado por el usuario
my $filename = $ARGV[0];

# Construir la ruta completa del fichero
my $file_path = File::Spec->catfile($fixed_path, $filename);

# Comprobar si el archivo existe
unless (-e $file_path) {
    die "El fichero '$file_path' no existe.\n";
}

# Hash para contar las apariciones de cada nodo
my %count;

# Abrir el archivo
open(my $fh, '<', $file_path) or die "No se puede abrir el archivo '$file_path': $!";

# Procesar cada línea del archivo
while (my $line = <$fh>) {
    chomp $line;
    my @fields = split /\^/, $line;
    my $nodo = $fields[7];  # Asumiendo que el campo de interés es el octavo (índice 7)
    $count{$nodo}++;
}

# Cerrar el archivo
close($fh);

# Variable para sumar todos los spots
my $total_spots = 0;

# Mostrar los resultados ordenados
print "NODO         Num.Spots\n";
print "--------     ---------\n";

foreach my $nodo (sort {$count{$b} <=> $count{$a}} keys %count) {
    printf "%-12s %d\n", $nodo, $count{$nodo};
    $total_spots += $count{$nodo};  # Sumar los spots al total
}

# Mostrar el total
print "--------     ---------\n";
printf "TOTAL        %d\n", $total_spots;
