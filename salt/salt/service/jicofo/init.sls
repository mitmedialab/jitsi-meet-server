{% from 'vars.jinja' import
  jicofo_domain_password,
  jicofo_user_password,
  server_id
with context %}

include:
  - repo.jitsi

jicofo-package:
  pkg.installed:
    - pkgs:
      - jicofo
    - require:
      - pkgrepo: jitsi-repo

/etc/jitsi/jicofo/config:
  file.managed:
    - source: salt://etc/jitsi/jicofo/config.jinja
    - template: jinja
    - context:
      server_id: {{ server_id }}
      jicofo_domain_password: {{ jicofo_domain_password }}
      jicofo_user_password: {{ jicofo_user_password }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: jicofo-package

jicofo-service:
  service.running:
    - name: jicofo
    - enable: true
    - watch:
      - pkg: jicofo-package
      - file: /etc/jitsi/jicofo/config

