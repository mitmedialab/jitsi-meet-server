{% from 'vars.jinja' import
  jitsi_meet_git_url,
  jitsi_meet_git_branch,
  jitsi_videobridge_password,
  jicofo_domain_password,
  jicofo_user_password,
  server_env,
  server_id,
  server_type
with context %}

# Set up the dependency line for the Git checkout. This is necessary because on
# Vagrant installs the checkout is an existing linked folder on the VM.
{% set git_checkout_dependency = server_type == 'vagrant' and 'file: /var/www/html/jitsi-meet' or 'git: jitsi-meet-git-checkout' -%}
# git_checkout_dependency is {{ git_checkout_dependency }}

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

{% if server_type != 'vagrant' -%}
jitsi-meet-git-checkout:
  git.latest:
    - name: {{ jitsi_meet_git_url }}
    - rev: {{ jitsi_meet_git_branch }}
    - target: /var/www/html/jitsi-meet
    - require:
      - file: /var/www/html/jitsi-meet
{% endif -%}

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
      - {{ git_checkout_dependency }}

npm-bootstrap-jitsi-meet:
  npm.bootstrap:
    - name: /var/www/html/jitsi-meet
    - require:
      - npm: jitsi-meet-node-packages
    - onchanges:
      - {{ git_checkout_dependency }}

build-jitsi-meet-app-bundle:
  cmd.run:
    # Their standard Makefile calls npm update, which has some kind of
    # recursive dependency bug. The bootstrap above is enough.
    - name: make compile && make uglify && make deploy && make clean
    - cwd: /var/www/html/jitsi-meet
    - use_vt: True
    - require:
      - npm: npm-bootstrap-jitsi-meet
    - onchanges:
      - {{ git_checkout_dependency }}

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


{% set ssl_key_prefix = server_type == 'vagrant' and 'local.' or '' -%}

/etc/ssl/private/{{ server_id }}.key:
  file.managed:
    - source: salt://software/jitsi-meet/certs/{{ ssl_key_prefix }}server.key
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
      - salt://software/jitsi-meet/certs/{{ ssl_key_prefix }}server.crt
      - salt://software/jitsi-meet/certs/{{ ssl_key_prefix }}chain.pem

add-prosody-user:
  cmd.run:
    - name: prosodyctl register focus auth.{{ server_id }} {{ jicofo_user_password }}
    - unless: test -n "`prosodyctl mod_listusers | grep focus@auth.{{ server_id }}`"
    - require:
      - file: /usr/lib/prosody/modules/mod_listusers.lua

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

add-nginx-user-to-ssl-cert-group:
  user.present:
    - name: www-data
    - optional_groups:
      - ssl-cert
    - remove_groups: False

{% if server_env == 'development' -%}
/usr/local/bin/rebuild-jitsi-meet.sh:
  file.managed:
    - source: salt://software/jitsi-meet/script/rebuild-jitsi-meet.sh
    - user: root
    - group: root
    - mode: 755
{% endif -%}

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
  nginx-service:
    service:
      - require:
        - {{ git_checkout_dependency }}
        - file: symlink-nginx-config
        - user: add-nginx-user-to-ssl-cert-group
      - watch:
        - file: /etc/nginx/sites-available/{{ server_id }}.conf
        - file: build-{{ server_id }}-ssl-cert
