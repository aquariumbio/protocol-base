import glob
import json
import subprocess

files = glob.glob('*/operation_types/*/definition.json')

for file in files:
  with open(file) as f:
    definition = json.load(f)

  if definition['name'].startswith('Test'):
    cmd = "pfish test -c '{}' -o '{}'".format(definition['category'], definition['name'])
    out = subprocess.check_output(cmd, shell=True)
    for o in out.decode("utf-8").split('\r\n'):
      print(o)