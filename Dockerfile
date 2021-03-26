#FROM ubuntu:20.04
FROM debian:buster

WORKDIR /usr/src/app

# Ensure we don't get asked questions and set container env
ARG DEBIAN_FRONTEND=noninteractive
ENV container docker

# Install everything required for systemd, including dbus, and other utils
# required. nano is for convenience
RUN apt-get update && apt-get dist-upgrade &&  apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    dbus \
    gnupg \
    init \
    libnss-mdns \
    lsb-release \
    nano \
    systemd \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Tonne of stuff we don't want systemd to run in-container
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    sys-kernel-config.mount \
    display-manager.service \
    getty@.service \
    systemd-logind.service \
    systemd-remount-fs.service \
    getty.target \
    graphical.target

# Get MySQL, and install it
RUN curl -L -o mysql-apt.deb https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb \
    && apt install ./mysql-apt.deb \
    && apt update \
    && apt -y install mysql-server \
    && rm -rf /var/lib/apt/lists/*

# Copy the preconfigured database across, ready for use
COPY mysql.tgz /usr/src/app/
RUN cd / \
    && tar xvfz /usr/src/app/mysql.tgz \
    && printf "[mysqld]\ndefault_authentication_plugin= mysql_native_password" >> /etc/mysql/my.cnf

# Get Zabbix release
# Currently skip TLS cert verification, because Zabbix have let their cert expire
RUN curl -k -o zabbix.deb https://repo.zabbix.com/zabbix/5.2/debian/pool/main/z/zabbix-release/zabbix-release_5.2-1+debian10_all.deb \
    && dpkg -i zabbix.deb \
    && apt update \
    && rm -rf /var/lib/apt/lists/*

# Ensure we can locally login
RUN sed -i $'s/\[mysqld\]/\[mysqld\]\\\nskip-grant-tables/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Install Zabbix server, agent and web requirements
RUN  apt update \
    && apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent \
    && rm -rf /var/lib/apt/lists/*

## Set Zabbix DB password
RUN echo 'DBPassword=zabbix' >> /etc/zabbix/zabbix_server.conf

# Enable the services
RUN systemctl enable mysql zabbix-server zabbix-agent apache2

# Copy entry script
COPY entry.sh /usr/src/app/

# Copy web config for Zabbix
RUN rm -f /usr/share/zabbix/config/zabbix.conf.php
COPY zabbix.conf.php /etc/zabbix/web/

# Ensure stop for systemd is honoured
STOPSIGNAL SIGRTMIN+3

# Start systemd as init
ENTRYPOINT [ "/usr/src/app/entry.sh" ]
