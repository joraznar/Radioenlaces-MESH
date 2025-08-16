#!/bin/sh

SERVER_IP="10.223.136.131"
BANDWIDTH="10M"
ITERACIONES=10

DURACIONES="5 10 15 20 25"

for DURACION in $DURACIONES
do
  LOGFILE="resultados_iperf_${DURACION}s.txt"
  
  echo "=== Inicio test iperf3 UDP - $(date) ===" > $LOGFILE
  echo "Servidor: $SERVER_IP, Ancho de banda: $BANDWIDTH, Duración: $DURACION s, Iteraciones: $ITERACIONES" >> $LOGFILE
  echo "" >> $LOGFILE

  i=1
  while [ $i -le $ITERACIONES ]
  do
    echo "Iteración $i / $ITERACIONES para duración ${DURACION}s..."
    echo -n "Iteración $i: " >> $LOGFILE

    # Ejecuta iperf3 y extrae la última línea que contiene 'receiver'
    iperf3 -c $SERVER_IP -u -b $BANDWIDTH -t $DURACION 2>/dev/null | grep "receiver" | tail -n 1 >> $LOGFILE

    i=$((i + 1))
  done

  echo "" >> $LOGFILE
  echo "=== Fin del test para duración ${DURACION}s ===" >> $LOGFILE
done

echo "Todos los tests finalizados."
