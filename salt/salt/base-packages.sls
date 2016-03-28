{% from 'vars.jinja' import server_env with context %}

base-packages:
  pkg.installed:
    - pkgs:
      - aptitude
      - bash-completion
      - colordiff
      - dbus
      - file
      - htop
      - libpam-systemd
      - logwatch
      - lynx
      - man-db
      - mutt
      - patch
      - patchutils
      # Needed for pkgrepo Salt state.
      - python-apt
      - sudo
      - tcpdump
      - telnet
      - tmux
      - traceroute
      - unzip
      - vim
{% if server_env != 'production' %}
      - gdb
{% endif %}
    - order: 3

