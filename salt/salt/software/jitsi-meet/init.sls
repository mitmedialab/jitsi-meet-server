{% from 'vars.jinja' import server_id, jitsi_videobridge_password, jicofo_password with context %}

include:
  - repo.jitsi

jitsi-meet-packages:
  pkg.installed:
    - pkgs:
      - default-jre
      - jicofo
      - jitsi-videobridge
      - nginx
      - prosody
    - require:
      - pkgrepo: jitsi-repo

/etc/prosody/conf.avail/{{ server_id }}.cfg.lua:
  file.managed:
    - source: salt://etc/prosody/conf.avail/domain.cfg.lua.jinja
    - template: jinja
    - context:
      server_id: {{ server_id }}
      jitsi_videobridge_password: {{ jitsi_videobridge_password }}
      jicofo_password: {{ jicofo_password }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: jitsi-meet-packages

symlink-prosody-config:
  file.symlink:
    - name: /etc/prosody/conf.d/{{ server_id }}.cfg.lua
    - target: /etc/prosody/conf.avail/{{ server_id }}.cfg.lua
    - require:
      - file: /etc/prosody/conf.avail/{{ server_id }}.cfg.lua
