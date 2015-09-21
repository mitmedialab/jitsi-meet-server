{% from 'vars.jinja' import
  jitsi_videobridge_password,
  server_id
with context %}

include:
  - repo.jitsi

jitsi-videobridge-package:
  pkg.installed:
    - pkgs:
      - jitsi-videobridge
    - require:
      - pkgrepo: jitsi-repo

/etc/jitsi/videobridge/config:
  file.managed:
    - source: salt://etc/jitsi/videobridge/config.jinja
    - template: jinja
    - context:
      server_id: {{ server_id }}
      jitsi_videobridge_password: {{ jitsi_videobridge_password }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: jitsi-videobridge-package

jitsi-videobridge-service:
  service.running:
    - name: jitsi-videobridge
    - enable: true
    - watch:
      - pkg: jitsi-videobridge-package
      - file: /etc/jitsi/videobridge/config

