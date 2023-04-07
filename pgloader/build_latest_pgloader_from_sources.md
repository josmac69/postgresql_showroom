# Build latest pgloader from sources (Debian 9)

Lately I had to replace installed pgloader with latest version build directly from sources. OS I did it on is Debian 9.
I found it is not exactly simple so here are my notes about it. You will need to install development tools and latest “sbcl” from sources too.

* ssh instance / server
* start “tmux” or similar sw
* update installed sw
  * sudo apt-get update
  * sudo apt-get upgrade

* install dev tools:
  * sudo apt-get install sbcl unzip libsqlite3-dev make curl gawk freetds-dev libzip-dev gcc cmake make -y

* clone latest sbcl and build latest sbcl from sources
  * rm -rf ~/sbcl
  * cd ~
  * git clone https://github.com/sbcl/sbcl.git
  * cd sbcl
  * sudo su
  * ./make.sh --fancy
  * ./install.sh
  * sbcl --version
  * exit

* build latest pgloader
  * rm -rf ~/pgloader
  * cd ~
  * git clone https://github.com/dimitri/pgloader.git
  * cd pgloader
  * sudo su
  * make pgloader
  * exit

* cd /home/upcload/pgloader/build/bin
* ./pgloader --version
