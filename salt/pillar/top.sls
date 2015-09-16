# Figure out if common file exists for install.
{% set common_file = [] -%}
# For each directory that can have files.
{% for root in opts['pillar_roots']['base'] -%}
  # Check for common file.
  {% set common_file_exists = salt['file.file_exists']('{0}/server/common.sls'.format(root)) -%}
  # If it exists set up for reading.
  {% if common_file_exists -%}
    {% if common_file.append(1) %}{% endif -%}
  {% endif -%}
{% endfor -%}
# common_file is {{ common_file|length }}

base:
  '*':
    - base
{% if common_file %}
    - server.common
{% endif %}
  'server:env:development':
    - match: grain
    - server.development

  'server:env:production':
    - match: grain
    - server.production

