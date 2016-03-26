## Installation

### Vagrant development servers.
 1. Install [Git](http://git-scm.com), [Vagrant](https://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org). OS X [Homebrew](http://brew.sh) users, consider easy installation via [Homebrew Cask](http://caskroom.io).
 1. Run the following command to checkout this project: ```git clone https://github.com/unhangout/jitsi-meet-server.git```
 1. From the command line, change to the <code>vagrant</code> directory, and you'll find <code>settings.sh.example</code>. Copy that file in the same directory to <code>settings.sh</code>.
 1. Edit to taste, the default values will most likely work just fine.
 1. Follow instructions below for configuring pillar data and SSL certs.
 1. From the command line, run <code>./development-environment-init.sh</code>.
 1. Once the script successfully completes the pre-flight checks, it will automatically handle the rest of the installation and setup. Relax, grab a cup of chai, and watch the setup process roll by on screen. :)
 1. Visit <code>https://jitsi-meet.stirlab.local</code> in your browser, and you should see the main page for Jitsi Meet.
 1. The setup script outputs optional configuration you can add to your ~/.ssh/config file, to enable easy root SSH access to the server if you configured an SSH pubkey.
 1. The installed virtual machine can be controlled like any other Vagrant VM. See [this Vagrant cheat sheet](http://notes.jerzygangi.com/vagrant-cheat-sheet) for more details.
 1. If for any reason the installation fails, or you just want to completely remove the installed virtual machine, run the <code>vagrant/kill-development-environment.sh</code> script from the command line.

### Production servers.
 1. Start with a fresh Debian 8 install
 1. Make sure the hostname of the server is set to the fully qualified domain name wanted for the installation. You can use the hostname command to set it, eg. ```hostname www.example.com```
 1. Load ```production/debian_bootstrap.sh``` to the server, make sure it's executable, and execute it.
 1. When it completes, follow the instructions below for configuring pillar data and SSL certs.
 1. Run ```salt-call state.highstate```

### Configuring pillar data

 * In the <code>salt/pillar/server</code> directory, you'll find three example configuration files: one for development, one for production, and one for common settings across environments.
 * Copy the relevant example files in the same directory, removing the .example extension (eg. <code>development.sls.example</code> becomes <code>development.sls</code>).
 * Edit the configurations to taste. You can reference salt/salt/vars.jinja to see what variables are available, and the defaults for each.
 * It's highly recommended to provide SSH public keys for those users you wish to have root access to the server. See the example configurations.

### Configuring SSL data

You need valid SSL certificates in order for WebRTC to function properly.

#### Vagrant development installations

   * Import <code>salt/salt/etc/ssl/local.chain.pem</code> as a trusted CA in your browser. This works with the default configured <code>jitsi-meet.stirlab.local</code> domain. It should be pretty easy to find instructions to import the certificate into all major browsers.

#### Other installations

   * Get some from a provider. Note that the common name of the certificate must match the hostname on production servers -- this allows Salt to auto configure the setup.
   * Place the following files into the <code>salt/salt/software/jitsi-meet/certs</code> directory:
     * server.crt: The server's SSL certificate.
     * server.key: The server's SSL private key.
     * chain.pem: The SSL chain file or root certificate authority.

Note that these SSL files are constructed on the server automatically from the files listed above -- if the server certificate, key, or chain files are ever replaced, these files should be removed, and Salt's <code>state.highstate</code> should be run to rebuild them:
   * /etc/ssl/private/[domain_name].key
   * /etc/ssl/private/[domain_name].pem

### Working with the Vagrant VM
 * The virtual machine can be started, stopped, and restarted from the host using the <code>vagrant/manage-vm.sh</code> script. Run without arguments for usage.
 * The following scripts are available to be run while SSH'd into the VM:
   * <code>/usr/local/bin/rebuild-jitsi-meet.sh</code>: Ensures all dependencies are installed, and compiles the Jitsi Meet web files.

### Known issues

None at this time.

### Todo

1. Figure out how to run compilation in dev/live reload mode, add support script for it.
