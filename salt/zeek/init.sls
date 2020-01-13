{%- set VERSION = salt['pillar.get']('static:soversion', '1.1.4') -%}
{%- set MASTER = salt['grains.get']('master') -%}
# Zeek Salt State
# Add Zeek group
zeekgroup:
  group.present:
    - name: zeek
    - gid: 937

# Add Zeek User
zeek:
  user.present:
    - uid: 937
    - gid: 937
    - home: /home/zeek

# Create some directories
zeekpolicydir:
  file.directory:
    - name: /opt/so/conf/zeek/policy
    - user: 937
    - group: 939
    - makedirs: True

# Zeek Log Directory
zeeklogdir:
  file.directory:
    - name: /nsm/zeek/logs
    - user: 937
    - group: 939
    - makedirs: True

# Zeek Spool Directory
zeekspooldir:
  file.directory:
    - name: /nsm/zeek/spool/manager
    - user: 937
    - makedirs: true

# Zeek extracted
zeekextractdir:
  file.directory:
    - name: /nsm/zeek/extracted
    - user: 937
    - group: 939
    - makedirs: True

zeeksfafincompletedir:
  file.directory:
    - name: /nsm/faf/files/incomplete
    - user: 937
    - makedirs: true

zeeksfafcompletedir:
  file.directory:
    - name: /nsm/faf/files/complete
    - user: 937
    - makedirs: true

# Sync the policies
zeekpolicysync:
  file.recurse:
    - name: /opt/so/conf/zeek/policy
    - source: salt://zeek/policy
    - user: 937
    - group: 939
    - template: jinja

# Sync node.cfg
nodecfgsync:
  file.managed:
    - name: /opt/so/conf/zeek/node.cfg
    - source: salt://zeek/files/node.cfg
    - user: 937
    - group: 939
    - template: jinja

plcronscript:
  file.managed:
    - name: /usr/local/bin/packetloss.sh
    - source: salt://zeek/cron/packetloss.sh
    - mode: 755

/usr/local/bin/packetloss.sh:
  cron.present:
    - user: root
    - minute: '*/10'
    - hour: '*'
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'

localzeeksync:
  file.managed:
    - name: /opt/so/conf/zeek/local.zeek
    - source: salt://zeek/files/local.zeek
    - user: 937
    - group: 939
    - template: jinja

so-zeek:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-zeek:HH{{ VERSION }}
    - privileged: True
    - binds:
      - /nsm/zeek/logs:/nsm/zeek/logs:rw
      - /nsm/zeek/spool:/nsm/zeek/spool:rw
      - /nsm/zeek/extracted:/nsm/zeek/extracted:rw
      - /opt/so/conf/zeek/local.zeek:/opt/zeek/share/zeek/site/local.zeek:ro
      - /opt/so/conf/zeek/node.cfg:/opt/zeek/etc/node.cfg:ro
      - /opt/so/conf/zeek/policy/securityonion:/opt/zeek/share/zeek/policy/securityonion:ro
      - /opt/so/conf/zeek/policy/custom:/opt/zeek/share/zeek/policy/custom:ro
      - /opt/so/conf/zeek/policy/intel:/opt/zeek/share/zeek/policy/intel:rw
    - network_mode: host
    - watch:
      - file: /opt/so/conf/zeek/local.zeek
      - file: /opt/so/conf/zeek/node.cfg
      - file: /opt/so/conf/zeek/policy
