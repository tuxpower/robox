#!/bin/bash

# Post configure tasks for Docker

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel
rpm -e --nodeps dhclient dhcp-libs dracut dracut-kernel grubby kmod grub2 centos-logos hwdata os-prober gettext bind-license freetype kmod-libs dracut firewalld dbus-glib dbus-python ebtables gobject-introspection pygobject3-base python-decorator python-slip python-slip-dbus kpartx kernel-firmware device-mapper device-mapper-event device-mapper-event-libs device-mapper-libs device-mapper-persistent-data e2fsprogs-libs kbd-misc iptables iptables-ipv6 haveged

rpm -Va --nofiles --nodigest
yum clean all

# Clean up unused directories
rm -rf /boot
rm -rf /etc/firewalld

# Stop services to avoid tarring sockets.
service abrt stop
service dbus stop
service mysqld stop
service postfix stop

#LANG="en_US"
#echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs='$LANG'\ntsflags=nodocs";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf
echo 'container' > /etc/yum/vars/infra

rm -f /usr/lib/locale/locale-archive

# Setup the login message instructions.
printf "Magma Daemon Development Environment\nTo download and compile magma, just execute the magma-build.sh script.\n\n" > /etc/motd

# Add a profile directive to send docker logins to the home directory.
printf "if [ \"\$PS1\" ]; then\n  cd \$HOME\nfi\n" > /etc/profile.d/home.sh

# Setup the locale properly - arrogantly assume everyone lives in the US.
localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

rm -rf /var/cache/yum/*
rm -f /tmp/ks-script*
rm -rf /var/log/*
rm -rf /tmp/*
rm -rf /etc/sysconfig/network-scripts/ifcfg-*

# Mark the docker box build time.
date --utc > /etc/docker_box_build_time

# Randomize the root password and then lock the root account.
dd if=/dev/urandom count=50 | md5sum | passwd --stdin root
passwd -l root

tar --create --numeric-owner --one-file-system --directory=/ --exclude=/tmp/magma-docker.tar --file=/tmp/magma-docker.tar .
