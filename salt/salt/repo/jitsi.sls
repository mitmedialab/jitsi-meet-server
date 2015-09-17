jitsi-repo:
  pkgrepo.managed:
    - humanname: Jitsi
    - name: deb http://download.jitsi.org/nightly/deb unstable/
    - file: /etc/apt/sources.list.d/jitsi.list
    - key_url: https://download.jitsi.org/nightly/deb/unstable/archive.key
    - refresh_db: true
