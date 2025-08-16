#!/bin/sh

# Configuración
SERVER="10.223.136.123"
BITRATES="10K 50K 100K 250K 500K"
TXPOWERS="2000 2500 3000 3200"  # 20, 25, 30 dBm
DURACION=20              # Duración por prueba (segundos)
INTERVALO=1                # Intervalo de salida iperf3
ITERACIONES=1              # Iteraciones por prueba
LOGDIR="/root/logs_udp_txpower"
TIMESTAMP=$(date +%F_%H-%M-%S)

mkdir -p "$LOGDIR"

# Archivo de resumen
RESUMEN="$LOGDIR/iperf3_udp_txpower_summary_${TIMESTAMP}.txt"
echo "Resumen pruebas UDP - $(date)" > "$RESUMEN"
echo "Servidor: $SERVER" >> "$RESUMEN"
echo "----------------------------------------" >> "$RESUMEN"

for tx in $TXPOWERS; do

    TXDBM=$(expr $tx / 100)
    echo "Estableciendo potencia TX a ${TXDBM} dBm"
    iw dev wlan0 set txpower fixed "$tx"
    sleep 2

    for bitrate in $BITRATES; do
        for iter in $(seq 1 $ITERACIONES); do

            LOGFILE="$LOGDIR/udp_tx${TXDBM}dBm_${bitrate}_iter${iter}_${TIMESTAMP}.log"
            echo ">> TX ${TXDBM} dBm | Bitrate $bitrate | Iteración $iter"
            echo "==== UDP TX ${TXDBM}dBm Bitrate $bitrate Iter $iter ====" > "$LOGFILE"
            echo "Fecha: $(date)" >> "$LOGFILE"
            echo "Servidor: $SERVER" >> "$LOGFILE"
            echo "----------------------------------------" >> "$LOGFILE"

            iperf3 -c "$SERVER" -u -b "$bitrate" -t "$DURACION" -i "$INTERVALO" -V >> "$LOGFILE" 2>&1

            FINAL_SUMMARY=$(tail -n 10 "$LOGFILE" | grep -A 3 "SUM" || tail -n 10 "$LOGFILE")
            echo "TX ${TXDBM}dBm | $bitrate | Iter $iter" >> "$RESUMEN"
            echo "$FINAL_SUMMARY" >> "$RESUMEN"
            echo "----------------------------------------" >> "$RESUMEN"

            sleep 2

        done
    done
done

echo "Todas las pruebas finalizadas - $(date)" >> "$RESUMEN"
echo "Logs en: $LOGDIR"
