#!/bin/bash

# Handles all details of setting up the development virtual server.

VAGRANT_CONFIG_DIR=$1
DEV_USER=$2
DEV_SERVER=$3
VM_INSTALL_DIR="${HOME}/vagrant/example"
GIT_CODE_DIR=""
SALT_DIR="`dirname $VAGRANT_CONFIG_DIR 2> /dev/null`/salt"
VAGRANT_VM_BOX="debian/jessie64"
SALT_MINION_ID="localhost.localdomain"
ALLOW_VM_FILE_SYNC_TIME="yes"
SSH_PORT="2222"

SCRIPT_NAME=`basename $0`

usage() {
echo "
This script initializes a fully functional development server on a
Vagrant virtual machine.

Usage: $SCRIPT_NAME <vagrant_config_dir> [dev_user] [dev_server]

  vagrant_config_dir: The directory containing the Vagrantfile to use.
  dev_user: The user name of the user on the main development server.
  dev_server: The SSH config name of the main development server.

dev_user and dev_server are optional, if provided they will be used to download
the Salt configuration. Otherwise, the Salt configuration will installed from
[vagrant_config_dir]/salt if it is found there.
"
}

if [ "$1" = "help" ]; then
  usage
  exit 1
fi

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

if [ -f ${VAGRANT_CONFIG_DIR}/settings.sh ]; then
  . ${VAGRANT_CONFIG_DIR}/settings.sh
fi

echo "Creating ${VM_INSTALL_DIR}..."
mkdir -p ${VM_INSTALL_DIR}

echo "Setting up Vagrant configuration for server..."
cd $VM_INSTALL_DIR
cp ${VAGRANT_CONFIG_DIR}/Vagrantfile .
# Cross-platform trick for sed inline editing.
sed -i.bak "s%###SSH_PORT###%${SSH_PORT}%g" Vagrantfile
rm Vagrantfile.bak
sed -i.bak "s%###VAGRANT_VM_BOX###%${VAGRANT_VM_BOX}%g" Vagrantfile
rm Vagrantfile.bak
sed -i.bak "s%###SALT_DIR###%${SALT_DIR}%g" Vagrantfile
rm Vagrantfile.bak
sed -i.bak "s%###SALT_MINION_ID###%${SALT_MINION_ID}%g" Vagrantfile
rm Vagrantfile.bak
if [ -n "${GIT_CODE_DIR}" ]; then
  sed -i.bak "s%###GIT_CODE_DIR###%${GIT_CODE_DIR}%g" Vagrantfile
  rm Vagrantfile.bak
fi
if [ -n "$DEV_SERVER" ]; then
  echo "Downloading salt config for dev user ${DEV_USER} from ${DEV_SERVER}..."
  rsync -avz --progress $DEV_SERVER:/home/${DEV_USER}/salt .
elif [ -d ${VAGRANT_CONFIG_DIR}/salt ]; then
  echo "Copying salt config from ${VAGRANT_CONFIG_DIR}/salt..."
  rsync -avz --progress ${VAGRANT_CONFIG_DIR}/salt .
fi
sed -i.bak "s%###SALT_MINION_ID###%${SALT_MINION_ID}%g" salt/minion
rm salt/minion.bak

echo "Temporarily uninstalling vagrant-vbguest plugin (if necessary)..."
vagrant plugin uninstall vagrant-vbguest

echo "Booting server..."
vagrant up --no-provision

#echo "Resetting SELinux..."
#vagrant ssh -- sudo sed -i -e "s/^SELINUX=.*/SELINUX=permissive/g" /etc/selinux/config

# This is necessary so that the vagrant-vbguest plugin can be properly
# installed.
#echo "Updating server kernel..."
#vagrant ssh -- "sudo apt-get -q -y update"
#vagrant ssh -- "sudo apt-get -q -y upgrade linux-image-amd64"
echo "Ensuring gcc/make/kernel-devel are installed..."
vagrant ssh -- "sudo apt-get -q -y install gcc make linux-kernel-headers linux-headers-\$(uname -r)"
echo "Installing some useful preliminary packages"
vagrant ssh -- "sudo apt-get -q -y install rsync vim"

vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-hostsupdater

# Reloading here allows the vagrant-vbguest plugin to handle its job before
# the rest of the install.
echo "Provisioning server..."
vagrant reload --provision

echo "Running auth.root Salt state..."
vagrant ssh -- "sudo salt-call state.sls auth.root"

if [ "$ALLOW_VM_FILE_SYNC_TIME" = "yes" ]; then
  # There is sometimes a slight delay in syncing files from the VM to a shared
  # host directory, allow time for it.
  echo "Waiting for files to sync to host..."
  sleep 60
fi

# Final reboot takes care of resetting SELinux, making sure all services
# come up on boot, etc.
echo "Rebooting server..."
vagrant reload

