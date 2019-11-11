# Create partitions and filesystems
## Possible for /tmp
disk_setup:
   ephmeral0:
       table_type: 'mbr'
       layout: True
       overwrite: False

fs_setup:
   - label: None,
     filesystem: ext3
     device: ephemeral0
     partition: auto

     