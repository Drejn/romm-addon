#!/usr/bin/env bash
set -e
BASE_PATH="/share/romm"
if [ -f /data/options.json ]; then
  BASE_PATH=$(python - <<'PY'
import json
try:
  o=json.load(open('/data/options.json'))
  print(o.get('base_path','/share/romm'))
except:
  print('/share/romm')
PY
)
fi
export ROMM_LIBRARY_PATH="$BASE_PATH/library"
export ROMM_ROMS_PATH="$BASE_PATH/roms"
export ROMM_MEDIA_PATH="$BASE_PATH/media"
export ROMM_CONFIG_PATH="$BASE_PATH/config"
export HOST=0.0.0.0
export PORT=8998
exec python -m romm
