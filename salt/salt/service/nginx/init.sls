nginx-package:
  pkg.installed:
    - name: nginx

nginx-service:
  service.running:
    - name: nginx
    - enable: true
    - watch:
      - pkg: nginx-package

