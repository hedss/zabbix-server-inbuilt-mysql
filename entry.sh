#!/bin/bash
set -m

GREEN='\033[0;32m'

# Is there a MySQL directory? If not, decompress the pre-created Zabbix
# DB into it. This could be a mounted volume, or a container layer.
if [ ! -d "/var/lib/mysql/zabbix" ]; then
	echo -e "${GREEN}No MySQL data directory found, decompressing."
    cd /;
    tar xvfz /usr/src/app/mysql.tgz;
else
	echo -e "${GREEN}MySQL data directory found."
fi

# systemd causes a POLLHUP for console FD to occur
# on startup once all other process have stopped.
# We need this sleep to ensure this doesn't occur, else
# logging to the console will not work.
sleep infinity &
for var in $(compgen -e); do
	printf '%q=%q\n' "$var" "${!var}"
done > /etc/docker.env
echo -e "${GREEN}Envvars written, restarting systemd as PID1."

exec /sbin/init
