#!/bin/bash
set -e

echo "Starting start.sh..."
echo "Initializing"

#===== CUSTOMIZE =====
# Mount network shared drive
MOUNT_FOLDER=""
MOUNT_HOST="/dev/sda1"
MOUNT_SOURCE="/$MOUNT_HOST/$MOUNT_FOLDER"
MOUNT_DEST="/data/mount"
mkdir -p "$MOUNT_DEST"
echo "Mounting $MOUNT_SOURCE to $MOUNT_DEST"
# mount "$MOUNT_SOURCE" "$MOUNT_DEST"
if [ $? -eq 0 ]; then
    echo "Mounted successfully."
else
    echo "Mounting failed!"
fi
df -h

# Setup Samba File Sharing
echo "Setting up Samba Drive"
npm install -g nodemon
cp ./smb.conf /etc/samba/smb.conf
SMBUSER=${SMBUSER:-root}
SMBPASS=${SMBPASS:-1234}
echo "Samba user name: $SMBUSER"
echo "Samba user password: $SMBPASS"
echo -ne "$SMBPASS\n$SMBPASS\n" | smbpasswd -a -s $SMBUSER
/etc/init.d/samba start
chmod 777 /data
npm start

#===== CUSTOMIZE =====
echo "Setting up Deluge"

# Configure transmission
: ${DOWNLOADS_DIR:="/data/Downloads"}
: ${DELUGE_CONFIG_DIR:="/data/deluge"}
: ${DELUGE_LOGLEVEL:="info"}
DELUGE_SETTINGS_PATH="$DELUGE_CONFIG_DIR/core.conf"
DELUGE_LOGS_PATH="$DELUGE_CONFIG_DIR/deluged.log"

# Setup Deluge
mkdir -p "$DOWNLOADS_DIR"
if [ -d "$DELUGE_CONFIG_DIR" ]; then
    # Exists
    echo "Deluge already configured at \"$DELUGE_CONFIG_DIR\"."
else
    # Does not exist
    echo "Deluge is not configured at \"$DELUGE_CONFIG_DIR\"."
    mkdir -p "$DELUGE_CONFIG_DIR"
    cp core.conf "$DELUGE_SETTINGS_PATH"
    echo "Created Deluge configuration at $DELUGE_SETTINGS_PATH"
fi

echo "Clean up old Deluge"
rm -f "$DELUGE_CONFIG_DIR/deluged.pid"

echo "Start Deluge daemon"
deluged --config=$DELUGE_CONFIG_DIR --loglevel=$DELUGE_LOGLEVEL --logfile=$DELUGE_LOGS_PATH
echo "Start Deluge-Web daemon"
deluge-web --config=$DELUGE_CONFIG_DIR --loglevel=$DELUGE_LOGLEVEL --port=80
