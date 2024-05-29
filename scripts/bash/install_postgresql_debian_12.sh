#!/bin/bash

PGVERSION=$1

if [ -z "$PGVERSION" ]; then
    echo "PGVERSION is not set. Exiting..."
    exit 1
fi

sudo apt update
sudo apt upgrade -y
sudo apt install curl wget -y

sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/pgdg.gpg

sudo apt update

sudo apt install postgresql-${PGVERSION} postgresql-server-dev-${PGVERSION} -y


