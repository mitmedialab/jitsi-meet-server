{% from 'vars.jinja' import server_env with context -%}

base:
  '*':
    - early-packages
    - update-packages
    - base-packages
    - service.firewall
    - service.network
    - auth.root
    - service.ssh
    - repo
    - misc
    - software.git
    - service.salt-minion
    - service.ntp
    - service.postfix
    - service.prosody
    - software.jitsi-meet
