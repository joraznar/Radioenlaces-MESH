#!/bin/sh

# Configuración
SERVER="10.223.136.123"
BITRATES="50K 100K 500K 1M"
DURACIONES="5 10 20 30 60"
ITERACIONES=1
LOGDIR="/root/logs2"
TIMESTAMP=$(date +%F_%H-%M-%S)

# Crear carpeta si no existe
mkdir -p "$LOGDIR"

# Archivo resumen
RESUMEN="$LOGDIR/iperf3_udp_summary_${TIMESTAMP}.txt"
echo "Resumen pruebas UDP - $(date)" > "$RESUMEN"
echo "Servidor: $SERVER" >> "$RESUMEN"
echo "----------------------------------------" >> "$RESUMEN"

for bitrate in $BITRATES; do
  for duracion in $DURACIONES; do
    for iter in $(seq 1 $ITERACIONES); do

      LOGFILE="$LOGDIR/iperf3_udp_${bitrate}_${duracion}s_iter${iter}_${TIMESTAMP}.log"
      echo "Ejecutando UDP - bitrate: $bitrate, duracion: ${duracion}s, iteracion: $iter"
      echo "==== UDP $bitrate ${duracion}s Iteracion $iter ====" > "$LOGFILE"
      echo "Fecha: $(date)" >> "$LOGFILE"
      echo "Servidor: $SERVER" >> "$LOGFILE"
      echo "----------------------------------------" >> "$LOGFILE"

      iperf3 -c "$SERVER" -u -b "$bitrate" -t "$duracion" -i 1 -V >> "$LOGFILE" 2>&1

      # Extraemos resumen final de iperf3 para que quede en el resumen
      FINAL_SUMMARY=$(tail -n 10 "$LOGFILE" | grep -A 3 "SUM" || tail -n 10 "$LOGFILE")
      echo "UDP $bitrate - ${duracion}s iter $iter" >> "$RESUMEN"
      echo "$FINAL_SUMMARY" >> "$RESUMEN"
      echo "----------------------------------------" >> "$RESUMEN"

      # Pequeña pausa para no saturar
      sleep 2

    done
  done
done

echo "Todas las pruebas finalizadas - $(date)" >> "$RESUMEN"
echo "Logs individuales en $LOGDIR"
