#!/bin/sh

# Configuración básica
IFACE="wlan0"  # Interfaz de radio
GCS_IP="10.223.136.50"  # IP del GCS (cámbiala o déjala vacía si no hay)

# Limpiar configuraciones previas
tc qdisc del dev $IFACE root 2>/dev/null
iptables -t mangle -F
iptables -t nat -F

# Marcar paquetes con DSCP por puerto
# Telemetría (alta prioridad)
iptables -t mangle -A PREROUTING -p udp --dport 14551 -j DSCP --set-dscp-class CS6

# Control (media)
iptables -t mangle -A PREROUTING -p udp --dport 14550 -j DSCP --set-dscp-class AF21

# Vídeo (baja)
iptables -t mangle -A PREROUTING -p udp --dport 5000 -j DSCP --set-dscp-class CS1

# Configurar Qdisc root con HTB
tc qdisc add dev $IFACE root handle 1: htb default 30

# Crear clases
tc class add dev $IFACE parent 1: classid 1:10 htb rate 6mbit prio 1
tc class add dev $IFACE parent 1: classid 1:20 htb rate 3mbit prio 2
tc class add dev $IFACE parent 1: classid 1:30 htb rate 1mbit prio 3

# Asociar clases con DSCP
tc filter add dev $IFACE parent 1: protocol ip prio 1 u32 match ip dsfield 0x30 0xfc flowid 1:10  # CS6
tc filter add dev $IFACE parent 1: protocol ip prio 1 u32 match ip dsfield 0x48 0xfc flowid 1:20  # AF21
tc filter add dev $IFACE parent 1: protocol ip prio 1 u32 match ip dsfield 0x08 0xfc flowid 1:30  # CS1

# Redirección opcional a GCS
if [ -n "$GCS_IP" ]; then
  echo "Redirigiendo tráfico a GCS en $GCS_IP..."
  iptables -t nat -A PREROUTING -p udp --dport 14551 -j DNAT --to-destination $GCS_IP:14551
  iptables -t nat -A PREROUTING -p udp --dport 14550 -j DNAT --to-destination $GCS_IP:14550
  iptables -t nat -A PREROUTING -p udp --dport 5000  -j DNAT --to-destination $GCS_IP:5000
fi

echo "QoS aplicado. Verifica con: tc -s qdisc show dev $IFACE"