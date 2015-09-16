# Overview
Vagrant/Salt configuration for automatically deploying [Jitsi Meet](https://jitsi.org/Projects/JitsiMeet) server.

## Installation

### Vagrant development servers.
 1. Install [Git](http://git-scm.com), [Vagrant](https://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org). OS X [Homebrew](http://brew.sh) users, consider easy installation via [Homebrew Cask](http://caskroom.io).
 1. Run the following command to checkout this project: ```git clone https://github.com/thehunmonkgroup/jitsi-meet-server.git```
 1. From the command line, change to the <code>vagrant</code> directory, and you'll find <code>settings.sh.example</code>. Copy that file in the same directory to <code>settings.sh</code>.
 1. Edit to taste, the default values will most likely work just fine.
 1. Follow instructions below for configuring pillar data and SSL certs.
 1. From the command line, run <code>./development-environment-init.sh</code>.
 1. Once the script successfully completes the pre-flight checks, it will automatically handle the rest of the installation and setup. Relax, grab a cup of chai, and watch the setup process roll by on screen. :)
 1. Visit <code>https://TODO: add URL</code> in your browser, and you should see the main page for Jitsi Meet.
 1. The setup script outputs optional configuration you can add to your .ssh/config file, to enable easy root SSH access to the server if you configured an SSH pubkey as above.
 1. The installed virtual machine can be controlled like any other Vagrant VM. See [this Vagrant cheat sheet](http://notes.jerzygangi.com/vagrant-cheat-sheet) for more details.
 1. If for any reason the installation fails, or you just want to completely remove the installed virtual machine, run the <code>vagrant/kill-development-environment.sh</code> script from the command line.

### Production servers.
 1. Start with a fresh Debian 8 install
 1. ```apt-get -y install git```
 1. ```mkdir -p /var/local/git```
 1. ```cd /var/local/git && git clone https://github.com/thehunmonkgroup/jitsi-meet-server.git```
 1. ```ln -s /var/local/git/jitsi-meet-server/salt /srv/salt```
 1. ```cd && wget -O install_salt.sh https://bootstrap.saltstack.com && sh install_salt.sh -P git v2014.7.6 && systemctl disable salt-minion.service && systemctl stop salt-minion.service```
 1. ```cp /var/local/git/unhangout-video-server/production/salt/minion /etc/salt/```
 1. Edit <code>/etc/salt/minion</code>, replacing <code>###SALT_MINION_ID###</code> with the hostname of the server.
 1. ```cp /var/local/git/unhangout-video-server/production/salt/grains.conf /etc/salt/minion.d/```
 1. Follow instructions below for configuring pillar data and SSL certs.
 1. ```salt-call state.highstate```

### Configuring pillar data

 * In the <code>salt/pillar/server</code> directory, you'll find three example configuration files: one for development, one for production, and one for common settings across environments.
 * Copy the relevant example files in the same directory, removing the .example extension (eg. <code>development.sls.example</code> becomes <code>development.sls</code>).
 * Edit the configurations to taste. You can reference salt/salt/vars.jinja to see what variables are available, and the defaults for each.
 * It's highly recommended to provide SSH public keys for those users you wish to have root access to the server. See the example configurations.

### Configuring SSL data

 * You need valid SSL certificates in order for WebRTC to function properly, so get some from a provider.
 * Place the following files into the <code>salt/salt/etc/ssl/</code> directory:
   * cert.pem: The server's SSL certificate.
   * key.pem: The server's SSL private key.
   * chain.pem: The SSL chain file or root certificate authority.

Note that these FreeSWITCH SSL files are constructed on the server automatically from the files listed above -- if the server certificate, key, or chain files are ever replaced, these files should be removed, and Salt's <code>state.highstate</code> should be run to rebuild them.
   * TODO: add files to delete.
