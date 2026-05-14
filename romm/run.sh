#!/usr/bin/env bash
set -e

BASE_PATH="{{ base_path }}"

export ROMM_LIBRARY_PATH="$BASE_PATH/library"
export ROMM_ROMS_PATH="$BASE_PATH/roms"
export ROMM_MEDIA_PATH="$BASE_PATH/media"
export ROMM_CONFIG_PATH="$BASE_PATH/config"

export HOST=0.0.0.0
export PORT=8998

python -m romm
