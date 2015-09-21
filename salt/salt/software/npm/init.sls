include:
  - software.nodejs

npm-package:
  pkg.installed:
    - name: npm
    - require:
      - pkg: nodejs-packages

