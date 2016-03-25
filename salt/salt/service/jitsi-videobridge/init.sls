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

/usr/share/jitsi-videobridge/.sip-communicator:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - require:
      - pkg: jitsi-videobridge-package

/usr/share/jitsi-videobridge/.sip-communicator/sip-communicator.properties:
  file.managed:
    - source: salt://service/jitsi-videobridge/sip-communicator.properties
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /usr/share/jitsi-videobridge/.sip-communicator

jitsi-videobridge-service:
  service.running:
    - name: jitsi-videobridge
    - enable: true
    - watch:
      - pkg: jitsi-videobridge-package
      - file: /etc/jitsi/videobridge/config
      - file: /usr/share/jitsi-videobridge/.sip-communicator/sip-communicator.properties

