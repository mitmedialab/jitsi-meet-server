{% from 'vars.jinja' import server_id with context %}

prosody-package:
  pkg.installed:
    - name: prosody

/usr/lib/prosody/modules/mod_listusers.lua:
  file.managed:
    - source: salt://service/prosody/mod/mod_listusers.lua
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: prosody-package

# Necessary to prevent errors about a missing localhost cert.
symlink-localhost-cert:
  file.symlink:
    - name: /etc/prosody/certs/localhost.crt
    - target: /etc/prosody/certs/localhost.cert
    - require:
      - pkg: prosody-package

prosody-service:
  service.running:
    - name: prosody
    - enable: true
    - require:
      - file: symlink-localhost-cert
    - watch:
      - pkg: prosody-package
      - file: /usr/lib/prosody/modules/mod_listusers.lua
