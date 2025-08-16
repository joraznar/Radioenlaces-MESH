#!/bin/sh

# Configuración
SERVER="10.223.136.123"
BITRATES="10K 50K 100K 250K 500K"
TXPOWERS="2000 2500 3200"  # Equivale a 20, 25 y 30 dBm
BANDWIDTHS="3 5 10"        # MHz
DURACION=30                # Puedes ajustar esto si quieres hacerlo más corto/largo
INTERVALO=1
ITERACIONES=1
LOGDIR="/root/logs_pruebas_rx"
TIMESTAMP=$(date +%F_%H-%M-%S)

mkdir -p "$LOGDIR"

RESUMEN="$LOGDIR/iperf3_udp_alcance_summary_${TIMESTAMP}.txt"
echo "Resumen pruebas UDP alcance - $(date)" > "$RESUMEN"
echo "Servidor: $SERVER" >> "$RESUMEN"
echo "----------------------------------------" >> "$RESUMEN"

for bw in $BANDWIDTHS; do

    # Configurar ancho de banda según tu sistema (esto es placeholder)
    echo "Configurando ancho de banda a ${bw} MHz"
    # Aquí deberías modificar el ancho de canal real si sabes el comando exacto.
    # Por ejemplo, si usas `/etc/config/wireless`, quizás necesites reiniciar wifi tras cambiarlo.
    # sleep 5  # Esperar un poco si el cambio necesita estabilizar

    for tx in $TXPOWERS; do

        echo "Estableciendo potencia TX a $(expr $tx / 100) dBm"
        iw dev wlan0 set txpower fixed "$tx"
        sleep 2  # Dar tiempo a aplicar cambio

        for bitrate in $BITRATES; do
            for iter in $(seq 1 $ITERACIONES); do

                LOGFILE="$LOGDIR/udp_bw${bw}MHz_tx${tx}dBm_${bitrate}_iter${iter}_${TIMESTAMP}.log"
                echo ">> Ancho ${bw}MHz | TX $(expr $tx / 100) dBm | Bitrate $bitrate | Iter $iter"
                echo "==== UDP BW ${bw}MHz TX $(expr $tx / 100)dBm Bitrate $bitrate Iter $iter ====" > "$LOGFILE"
                echo "Fecha: $(date)" >> "$LOGFILE"
                echo "Servidor: $SERVER" >> "$LOGFILE"
                echo "----------------------------------------" >> "$LOGFILE"

                iperf3 -c "$SERVER" -u -b "$bitrate" -t "$DURACION" -i "$INTERVALO" -V >> "$LOGFILE" 2>&1

                FINAL_SUMMARY=$(tail -n 10 "$LOGFILE" | grep -A 3 "SUM" || tail -n 10 "$LOGFILE")
                echo "BW ${bw}MHz | TX $(expr $tx / 100)dBm | $bitrate | Iter $iter" >> "$RESUMEN"
                echo "$FINAL_SUMMARY" >> "$RESUMEN"
                echo "----------------------------------------" >> "$RESUMEN"

                sleep 2

            done
        done
    done
done

echo "Todas las pruebas finalizadas - $(date)" >> "$RESUMEN"
echo "Logs en: $LOGDIR"
