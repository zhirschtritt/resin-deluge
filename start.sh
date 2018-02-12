#!/bin/bash
set -e

echo "Starting start.sh..."
echo "Initializing"

# Setup Samba File Sharing
echo "Setting up Samba Drive"
cp ./smb.conf /etc/samba/smb.conf
SMBUSER=${SMBUSER:-root}
SMBPASS=${SMBPASS:-1234}
echo "Samba user name: $SMBUSER"
echo "Samba user password: $SMBPASS"
echo -ne "$SMBPASS\n$SMBPASS\n" | smbpasswd -a -s $SMBUSER
/etc/init.d/samba start
mkdir -p /mnt/torrents
chmod 777 /mnt/torrents

#===== CUSTOMIZE =====
echo "Setting up Deluge"

# Configure transmission
: ${TORRENTS_DIR:="/mnt/torrents"}
: ${DOWNLOADING_DIR:="/mnt/torrents/downloading"}
: ${COMPLETED_DIR:="/mnt/torrents/completed"}
: ${WATCH_DIR:="/mnt/torrents/watch"}
: ${BACKUP_DIR:="/mnt/torrents/backup"}

: ${DELUGE_CONFIG_DIR:="/mnt/deluge/deluge_config"}
: ${DELUGE_LOGLEVEL:="info"}
: ${DELUGE_PLUGINS_DIR:="/mnt/deluge/plugins"}
DELUGE_SETTINGS_PATH="$DELUGE_CONFIG_DIR/core.conf"
DELUGE_LOGS_PATH="$DELUGE_CONFIG_DIR/deluged.log"

# Setup Deluge
mkdir -p "$TORRENTS_DIR"
mkdir -p "$DOWNLOADING_DIR"
mkdir -p "$COMPLETED_DIR"
mkdir -p "$WATCH_DIR"
mkdir -p "$BACKUP_DIR"
chmod -R 777 /mnt/torrents
if [ -d "$DELUGE_CONFIG_DIR" ]; then
    # Exists
    echo "Deluge already configured at \"$DELUGE_CONFIG_DIR\"."
else
    # Does not exist
    echo "Deluge is not configured at \"$DELUGE_CONFIG_DIR\"."
    mkdir -p "$DELUGE_CONFIG_DIR"
    mkdir -p "$DELUGE_PLUGINS_DIR"
    cp core.conf "$DELUGE_SETTINGS_PATH"
    echo "Created Deluge configuration at $DELUGE_SETTINGS_PATH"
fi

echo "Clean up old Deluge"
rm -f "$DELUGE_CONFIG_DIR/deluged.pid"

echo "Start Deluge daemon"
deluged --config=$DELUGE_CONFIG_DIR --loglevel=$DELUGE_LOGLEVEL --logfile=$DELUGE_LOGS_PATH
echo "Start Deluge-Web daemon"
deluge-web --config=$DELUGE_CONFIG_DIR --loglevel=$DELUGE_LOGLEVEL --port=80
