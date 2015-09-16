{% from 'vars.jinja' import server_env, ssh_pubkeys_root, server_encryption_password, freeswitch_ip with context %}

{% for user, data in ssh_pubkeys_root.iteritems() %}
sshkey-{{ user }}:
  ssh_auth:
    - present
    - user: root
    - enc: {{ data.enc|default('ssh-rsa') }}
    - name: {{ data.key }}
    - comment: {{ user }}
{% endfor %}

/root/.bashrc.d:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755

/root/bin:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755

