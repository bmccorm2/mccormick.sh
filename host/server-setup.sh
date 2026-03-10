#! /bin/bash

apt update && \
    apt install \
    htop ncdu rsync fish fail2ban lsof micro ufw unbound

apt remove exim4 exim4-base exim4-config exim4-daemon-light &&
    apt autoremove --purge

groupadd -g 5000 vmail
useradd -u 5000 -g vmail -s /usr/bin/false -M vmail

useradd -m -s /usr/bin/fish -G docker,sudo,users bryan

TZ=America/Denver
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone