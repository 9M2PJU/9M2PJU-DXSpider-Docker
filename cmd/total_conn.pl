#!/usr/bin/perl

#
# Calculates the connection time per user in the current year.
#
# Usage. From command line run: ./total_conn.pl
#
# To be copied to /spider/local_cmd
#
# Kin EA3CV, ea3cv@cronux.net
#
# 20200423 v0.3a
#

# Call       Connected  Spots  Total Time
# ---------  ---------  -----  --------------------
# EA3GOP     87         0       28 d 08 h 44 m 09 s
# EA3IMR     9          7       27 d 06 h 29 m 54 s
# EA3HLM     288        6       19 d 09 h 36 m 04 s
# EA5JN      33         169     17 d 13 h 54 m 15 s
# KC1CAB     56         0       12 d 23 h 10 m 16 s

use 5.10.0;
use strict;
use warnings;

# Definimos una función para convertir segundos en una cadena de texto que describe el tiempo
sub format_time {
    my ($seconds) = @_;
    my $minutes = int($seconds / 60) % 60;
    my $hours = int($seconds / 3600) % 24;
    my $days = int($seconds / 86400);
    return sprintf("%02d d %02d h %02d m %02d s", $days, $hours, $minutes, $seconds % 60);
}

# Obtenemos el año actual
my ($sec, $min, $hour, $day, $month, $year) = localtime();
my $current_year = $year + 1900;

# Creamos una tabla hash para almacenar los tiempos de conexión por usuario
my %total_time;
my %connection_count;
my %spot_count;

# Iteramos a través de los archivos de registro
foreach my $file (glob("/spider/local_data/log/$current_year/*.dat")) {
#foreach my $file (glob("/root/volumenes/dxspider/nodo-2/local_data/log/$current_year/*.dat")) {

    # Abrimos el archivo y lo leemos línea por línea
    open(my $fh, "<", $file) or die "No se pudo abrir el archivo $file: $!";
    while (my $line = <$fh>) {

        # Analizamos la línea para encontrar comandos DX y conexiones/desconexiones
        if ($line =~ /^(\d+)\^DXCommand\^(\S+) (connected|disconnected)/) {
            my ($timestamp, $call, $status) = ($1, $2, $3);

            if ($call eq 'SK0MMR' || $call eq 'SK1MMR') {
                next;
            }

            # Si es una conexión, almacenamos el tiempo de conexión anterior para este usuario
            if ($status eq "connected") {
                if (exists $total_time{$call} && $total_time{$call}{last_timestamp}) {
                    $total_time{$call}{total_seconds} += $timestamp - $total_time{$call}{last_timestamp};
                }
                $total_time{$call}{last_timestamp} = $timestamp;
                $connection_count{$call}++;
            }

            # Si es una desconexión, calculamos el tiempo de conexión para este usuario y lo agregamos a su tiempo total
            elsif ($status eq "disconnected") {
                if (exists $total_time{$call} && $total_time{$call}{last_timestamp}) {
                    $total_time{$call}{total_seconds} += $timestamp - $total_time{$call}{last_timestamp};
                    $total_time{$call}{last_timestamp} = 0;
                }
            }
        }

        # Contamos los spots que contiene ^cmd^ y |dx|
        if ($line =~ /\^cmd\^(\S+)\|dx\|/) {
            my $call = $1;
            $call =~ s/\|.*//;
            $spot_count{$call}++;
        }
    }
    close($fh);
}

# Imprimimos los resultados ordenados por tiempo total conectado
printf("%-10s %-10s %-6s %-12s\n", "Call", "Connected", "Spots", "Total Time");
printf("%-10s %-10s %-6s %-12s\n", "---------", "---------", "-----", "--------------------");
foreach my $call (sort {
        ($total_time{$b}{total_seconds} || 0) <=> ($total_time{$a}{total_seconds} || 0)
    } keys %total_time) {
    my $total_seconds = $total_time{$call}{total_seconds} || 0;
    my $count = $connection_count{$call} || 0;
    my $spots = $spot_count{$call} || 0;
    printf("%-10s %-10d %-3s     %-20s\n", $call, $count, $spots, format_time($total_seconds));
}
