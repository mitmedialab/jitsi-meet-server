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

prosody-service:
  service.running:
    - name: prosody
    - enable: true
    - watch:
      - pkg: prosody-package
      - file: /usr/lib/prosody/modules/mod_listusers.lua
