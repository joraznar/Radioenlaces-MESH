#!/bin/sh

# Configuración general
SERVER="10.223.136.123"
BITRATES="10K 50K 100K 250K 500K"
TXPOWERS="2000 2500 3000 3200"
DURACION=20
INTERVALO=1
ITERACIONES=1
LOGDIR="/root/logs_udp_txpower"
TIMESTAMP=$(date +%F_%H-%M-%S)
IFACE="wlan0"

mkdir -p "$LOGDIR"

RESUMEN="$LOGDIR/iperf3_udp_txpower_summary_${TIMESTAMP}.txt"
echo "Resumen pruebas UDP - $(date)" > "$RESUMEN"
echo "Servidor: $SERVER" >> "$RESUMEN"
echo "----------------------------------------" >> "$RESUMEN"

for tx in $TXPOWERS; do
    TXDBM=$(expr $tx / 100)
    echo "Estableciendo potencia TX a ${TXDBM} dBm"
    iw dev "$IFACE" set txpower fixed "$tx"
    sleep 2

    for bitrate in $BITRATES; do
        for iter in $(seq 1 $ITERACIONES); do
            LOGFILE="$LOGDIR/udp_tx${TXDBM}dBm_${bitrate}_iter${iter}_${TIMESTAMP}.log"
            METRICS_CSV="$LOGDIR/metrics_tx${TXDBM}dBm_${bitrate}_iter${iter}_${TIMESTAMP}.csv"

            echo ">> TX ${TXDBM} dBm | Bitrate $bitrate | Iteración $iter"
            echo "==== UDP TX ${TXDBM}dBm Bitrate $bitrate Iter $iter ====" > "$LOGFILE"
            echo "Fecha: $(date)" >> "$LOGFILE"
            echo "Servidor: $SERVER" >> "$LOGFILE"
            echo "----------------------------------------" >> "$LOGFILE"

            # Encabezado CSV
            echo "Timestamp,RSSI(dBm),Noise(dBm),SNR(dB)" > "$METRICS_CSV"

            # Lanza iperf3 en segundo plano
            iperf3 -c "$SERVER" -u -b "$bitrate" -t "$DURACION" -i "$INTERVALO" -V >> "$LOGFILE" 2>&1 &
            IPERF_PID=$!

            # Mientras iperf esté corriendo, loguear métricas una vez por segundo
            for i in $(seq 1 "$DURACION"); do
                TIME=$(date "+%Y-%m-%d %H:%M:%S")
                RSSI=$(iw dev "$IFACE" link | grep 'signal:' | awk '{print $2}')
                [ -z "$RSSI" ] && RSSI="N/A"
                NOISE="N/A"
                SNR="N/A"

                echo "$TIME,$RSSI,$NOISE,$SNR" >> "$METRICS_CSV"
                sleep 1
            done

            wait "$IPERF_PID" 2>/dev/null

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
