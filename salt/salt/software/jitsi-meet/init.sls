{% from 'vars.jinja' import
  jitsi_meet_git_url,
  jitsi_meet_git_branch,
  jitsi_videobridge_password,
  jicofo_domain_password,
  jicofo_user_password,
  server_id
with context %}

include:
  - repo.jitsi
  - software.npm
  - service.prosody
  - service.nginx
  - service.jitsi-videobridge
  - service.jicofo

jitsi-meet-node-packages:
  npm.installed:
    - pkgs:
      - browserify
    - require:
      - pkg: npm-package

/var/www/html/jitsi-meet:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - require:
      - pkg: nginx-package

jitsi-meet-git-checkout:
  git.latest:
    - name: {{ jitsi_meet_git_url }}
    - rev: {{ jitsi_meet_git_branch }}
    - target: /var/www/html/jitsi-meet
    - require:
      - file: /var/www/html/jitsi-meet

npm-bootstrap-jitsi-meet:
  npm.bootstrap:
    - name: /var/www/html/jitsi-meet
    - require:
      - npm: jitsi-meet-node-packages
    - watch:
      - git: jitsi-meet-git-checkout

build-jitsi-meet-app-bundle:
  cmd.run:
    - name: make
    - cwd: /var/www/html/jitsi-meet
    - unless: test -f /var/www/html/jitsi-meet/libs/app.bundle.min.js && test -f /var/www/html/jitsi-meet/libs/app.bundle.min.map
    - use_vt: True
    - require:
      - npm: npm-bootstrap-jitsi-meet
    - watch:
      - git: jitsi-meet-git-checkout

/var/www/html/jitsi-meet/config.js:
  file.managed:
    - source: salt://software/jitsi-meet/config.js.jinja
    - template: jinja
    - context:
      server_id: {{ server_id }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - git: jitsi-meet-git-checkout

/etc/prosody/conf.avail/{{ server_id }}.cfg.lua:
  file.managed:
    - source: salt://etc/prosody/conf.avail/domain.cfg.lua.jinja
    - template: jinja
    - context:
      server_id: {{ server_id }}
      jitsi_videobridge_password: {{ jitsi_videobridge_password }}
      jicofo_domain_password: {{ jicofo_domain_password }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: prosody-package

symlink-prosody-config:
  file.symlink:
    - name: /etc/prosody/conf.d/{{ server_id }}.cfg.lua
    - target: /etc/prosody/conf.avail/{{ server_id }}.cfg.lua
    - require:
      - file: /etc/prosody/conf.avail/{{ server_id }}.cfg.lua

/etc/ssl/private/{{ server_id }}.key:
  file.managed:
    - source: salt://software/jitsi-meet/certs/server.key
    - user: root
    - group: ssl-cert
    - mode: 640

/etc/ssl/certs/{{ server_id }}.pem:
  file.managed:
    - user: root
    - group: root
    - mode: 644

build-{{ server_id }}-ssl-cert:
  file.append:
    - name: /etc/ssl/certs/{{ server_id }}.pem
    - sources:
      - salt://software/jitsi-meet/certs/server.crt
      - salt://software/jitsi-meet/certs/chain.pem

add-prosody-user:
  cmd.run:
    - name: prosodyctl register focus auth.{{ server_id }} {{ jicofo_user_password }}
    - unless: test -n "`prosodyctl mod_listusers | grep focus@auth.{{ server_id }}`"
    - require:
      - file: /usr/lib/prosody/modules/mod_listusers.lua

/usr/share/jitsi-videobridge/.sip-communicator:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - require:
      - pkg: jitsi-videobridge-package

/usr/share/jitsi-videobridge/.sip-communicator/sip-communicator.properties:
  file.managed:
    - contents: "org.jitsi.impl.neomedia.transform.srtp.SRTPCryptoContext.checkReplay=false"
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /usr/share/jitsi-videobridge/.sip-communicator

/etc/nginx/sites-available/{{ server_id }}.conf:
  file.managed:
    - source: salt://etc/nginx/sites-available/jitsi-meet.conf.jinja
    - template: jinja
    - context:
      server_id: {{ server_id }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx-package

symlink-nginx-config:
  file.symlink:
    - name: /etc/nginx/sites-enabled/{{ server_id }}.conf
    - target: /etc/nginx/sites-available/{{ server_id }}.conf
    - require:
      - file: /etc/nginx/sites-available/{{ server_id }}.conf

extend:
  prosody-service:
    service:
      - require:
        - file: symlink-prosody-config
      - watch:
        - file: /etc/prosody/conf.avail/{{ server_id }}.cfg.lua
        - file: /etc/ssl/private/{{ server_id }}.key
        - file: build-{{ server_id }}-ssl-cert
        - cmd: add-prosody-user
  jitsi-videobridge-service:
    service:
      - watch:
        - file: /usr/share/jitsi-videobridge/.sip-communicator/sip-communicator.properties
  nginx-service:
    service:
      - require:
        - git: jitsi-meet-git-checkout
        - file: symlink-nginx-config
      - watch:
        - file: /etc/nginx/sites-available/{{ server_id }}.conf
