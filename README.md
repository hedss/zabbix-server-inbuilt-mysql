# Zabbix Docker Image with inbuilt MySQL

## Why does this exist?
I recently needed to use Zabbix in an environment where I didn't want to use MySQL in a separate container. I just wanted a self-contained image I could drop into another system.

As an aside, you should never run `systemd` in a container, for obvious reasons.

## What is this?
This is Zabbix and MySQL running via `systemd` in a container. Yeah.

`systemd` has a couple of gotchyas under Docker. You need to run it in a semi-privileged mode. See 'How do I run this?'.

The repo includes a pre-configured MySQL DB that is ready to start!

On startup, the container will test for the prescence of the Zabbix DB. If it doesn't exist, it'll write a preconfigured DB to `/var/lib/mysql`. If it does exist, it'll use what's there. This means you can attach a persistent volume to the container to keep data around.

## How do I build this?
`docker build -t zabbix-server-inbuilt-mysql .`

## I am lazy, do I have to build this?
No, I am also lazy:
`docker pull whaleway/zabbix-server-inbuilt-mysql:latest`

## How do I run this?
`docker-compose up -d`

I even wrote a compose file for you, isn't that nice? You can work out an individual run command based on this easily enough.

Once started, simply login to `http://localhost:8011/zabbix`.

Enjoy!
