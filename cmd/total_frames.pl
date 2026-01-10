#!/usr/bin/perl

#
# Utility to count IN/OUT frames per node
#
# To be copied to /spider/local_cmd/
#
# From the command line: ./total_frames.pl <day>.dat
#
# Created by Kin EA3CV
#
# 20230906 v0.0
#

use strict;
use warnings;
use File::Spec;
use POSIX qw(strftime);

# Obtener el año actual
my $current_year = strftime "%Y", localtime;

# Ruta fija con el año actual
my $fixed_path = "/spider/local_data/debug/$current_year";

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

# Hashes para contar las apariciones de cada PCxx por nodo
my (%in_count, %out_count);
my %pc_types;  # Para mantener un registro de todos los PCxx vistos

# Abrir el archivo
open(my $fh, '<', $file_path) or die "No se puede abrir el archivo '$file_path': $!";

# Procesar cada línea del archivo
while (my $line = <$fh>) {
    chomp $line;
    next unless $line =~ /\^/;  # Saltar líneas que no contienen '^'

    if ($line =~ /<-/) {
        # IN - Nodo origen
        my ($node, $pc_type) = $line =~ /<-\s+I\s+(\S+)\s+PC(\d{2})\^/;
        if ($node && $pc_type) {
            $in_count{$node}{$pc_type}++;
            $pc_types{$pc_type} = 1;
        }
    } elsif ($line =~ /->/) {
        # OUT - Nodo destino
        my ($node, $pc_type) = $line =~ /->\s+D\s+(\S+)\s+PC(\d{2})\^/;
        if ($node && $pc_type) {
            $out_count{$node}{$pc_type}++;
            $pc_types{$pc_type} = 1;
        }
    }
}

# Cerrar el archivo
close($fh);

# Obtener una lista ordenada de todos los PCxx que hemos visto
my @sorted_pc_types = sort { $a cmp $b } keys %pc_types;

# Determinar el ancho de las columnas
my $node_width = 12;
my $pc_width = 8;

# Función para imprimir una tabla con totales
sub print_table_with_totals {
    my ($header, $count_hash) = @_;

    # Imprimir la cabecera
    print "$header\n";
    print sprintf("%-${node_width}s", "Nodo"), " ";
    foreach my $pc_type (@sorted_pc_types) {
        print sprintf("%-${pc_width}s", "PC$pc_type"), " ";
    }
    print "\n";
    print "-" x ($node_width + $pc_width * @sorted_pc_types + @sorted_pc_types - 1), "\n";

    # Inicializar totales
    my %totals;
    foreach my $pc_type (@sorted_pc_types) {
        $totals{$pc_type} = 0;
    }

    # Imprimir la tabla
    foreach my $node (sort keys %$count_hash) {
        print sprintf("%-${node_width}s", $node), " ";
        foreach my $pc_type (@sorted_pc_types) {
            my $count = $count_hash->{$node}{$pc_type} // 0;  # Usar 0 si no existe
            $totals{$pc_type} += $count;  # Sumar al total
            print sprintf("%-${pc_width}d", $count), " ";
        }
        print "\n";
    }

    # Imprimir totales
    print "-" x ($node_width + $pc_width * @sorted_pc_types + @sorted_pc_types - 1), "\n";
    print sprintf("%-${node_width}s", "Total"), " ";
    foreach my $pc_type (@sorted_pc_types) {
        print sprintf("%-${pc_width}d", $totals{$pc_type}), " ";
    }
    print "\n\n";
}

# Imprimir las tablas con totales
print_table_with_totals("IN Node", \%in_count);
print_table_with_totals("OUT Node", \%out_count);
