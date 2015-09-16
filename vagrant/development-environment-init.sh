#!/bin/bash

# This script handles all of the setup to build a fully functioning
# development environment using vagrant and salt.


DEV_SERVER=""
SSH_PORT="2222"
SSH_CONFIG_LABEL="example"
MESSAGE_STORE=""
VM_INSTALL_DIR="${HOME}/vagrant/example"
GIT_CODE_DIR=""
GIT_CODE_BRANCH="master"

SCRIPT_NAME=`basename $0`

usage() {
echo "
This script handles all necessary host-level tasks necessary for
installing a local development server via Vagrant.

Usage: $SCRIPT_NAME
"
}

if [ "$1" = "help" ]; then
  usage
  exit 1
fi

if [ $# -ne 0 ]; then
  usage
  exit 1
fi

find_full_path_to_file() {
  local CWD=`pwd`
  local DIR=`dirname $0`
  local FULL_PATH=`echo "$(cd "$DIR"; pwd)"`
  cd $CWD
  echo "$FULL_PATH"
}

VAGRANT_CONFIG_DIR=`find_full_path_to_file`

if [ -f ${VAGRANT_CONFIG_DIR}/settings.sh ]; then
  . ${VAGRANT_CONFIG_DIR}/settings.sh
fi
PORTS_TO_CHECK="${SSH_PORT}"

CWD=`pwd`

add_message() {
  local new_message=$1
  MESSAGE_STORE="$MESSAGE_STORE
 * $new_message"
}

check_executable() {
  local executable=$1
  local software=$2
  which $executable &>/dev/null
  if [ $? -ne 0 ]; then
    add_message "Test for $software failed, please install it to proceed"
  fi
}

setup_git_repo() {
  if [ -n "${GIT_CODE_DIR}" ] && [ ! -d "${GIT_CODE_DIR}" ]; then
    echo "Setting up $GIT_CLONE_URL repository in ${GIT_CODE_DIR}..."
    git clone $GIT_CLONE_URL $GIT_CODE_DIR
    cd ${GIT_CODE_DIR}
    if [ "$GIT_CODE_BRANCH" = "master" ]; then
      git branch --set-upstream-to=origin/master master
      git config remote.origin.push HEAD
    else
      local git_branch=`git rev-parse --abbrev-ref HEAD`
      if [ "$git_branch" != "$GIT_CODE_BRANCH" ]; then
        echo "Checking out ${GIT_CODE_BRANCH}, and setting up remote tracking..."
        git checkout -t origin/${GIT_CODE_BRANCH}
      fi
    fi
  fi
}

if [ -n "$DEV_SERVER" ]; then
  echo -n "Enter the username you were given for the main development
  server (${DEV_SERVER}): "
  read DEV_USERNAME
fi

echo "Running pre-flight checks..."
echo "Testing for internet connectivity..."
ping -c1 -q google.com &> /dev/null
if [ $? -ne 0 ]; then
  add_message "Test for internet connectivity failed, you must have an active internet connection"
fi

if [ -n "$DEV_USER" ]; then
  echo "Checking for SSH access for ${DEV_USERNAME}@${DEV_SERVER}"
  ssh ${DEV_SERVER} ls /home/${DEV_USERNAME} &> /dev/null
  if [ $? -ne 0 ]; then
    add_message "Test for SSH access for ${DEV_USERNAME}@${DEV_SERVER} failed. Make
  sure you have a user account there, and the proper config in your
  ${HOME}/.ssh/config file."
  fi

  echo "Checking for valid Salt config..."
  ssh ${DEV_SERVER} ls /home/${DEV_USERNAME}/salt/minion &> /dev/null
  if [ $? -ne 0 ]; then
    add_message "Test for valid salt config for user ${DEV_USERNAME} failed. Ask the
  system admin to set up your Salt access."
  fi
fi

for port in $PORTS_TO_CHECK; do
  echo "Checking port $port for availability..."
  open=`lsof -i -P | grep LISTEN | awk '{print $9}' | grep $port`
  if [ -n "$open" ]; then
    add_message "Port $port is currently running another process, please disable it"
  fi
done

echo "Checking for Git..."
check_executable git Git

echo "Checking for rsync..."
check_executable rsync rsync

echo "Checking for Vagrant..."
check_executable vagrant Vagrant

echo "Checking for Virtualbox..."
check_executable VBoxManage Virtualbox

if [ -n "$MESSAGE_STORE" ]; then
  echo
  echo "ERROR: pre-flight checks failed, correct the issues and run again"
  echo "$MESSAGE_STORE"
  exit 1
fi

echo "All pre-flight checks passed"

echo "Initializing development server install..."
${VAGRANT_CONFIG_DIR}/vm-init.sh "$VAGRANT_CONFIG_DIR" "$DEV_USERNAME" "$DEV_SERVER"

if [ -z "$MESSAGE_STORE" ]; then
  echo
  echo "Deployment successful."
  RET=0
else
  echo
  echo "ERROR: Some deployment tasks failed, check the output below for items
that may not be operating properly."
  echo "$MESSAGE_STORE"
  RET=1
fi

echo
echo "Add the following entry to your .ssh/config file, then use
'ssh ${SSH_CONFIG_LABEL}' to access the installed VM:

Host ${SSH_CONFIG_LABEL}
  Hostname localhost
  Port ${SSH_PORT}
  User root
  HostKeyAlias ${SSH_CONFIG_LABEL}

Note that you must install your hosts's SSH public key on the virtual machine
in order for this to work.
"

cd $CWD

exit $RET

