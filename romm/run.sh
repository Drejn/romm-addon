#!/usr/bin/env bash
set -e

BASE_PATH="{{ base_path }}"  # viene sostituito da Home Assistant

export ROMM_LIBRARY_PATH="$BASE_PATH/library"
export ROMM_ROMS_PATH="$BASE_PATH/roms"
export ROMM_MEDIA_PATH="$BASE_PATH/media"
export ROMM_CONFIG_PATH="$BASE_PATH/config"

# eventuali altre env che già stai passando (DB, ecc.)

# porta su cui RomM ascolta
export PORT=8998
export HOST=0.0.0.0

# avvia RomM (come fa l'immagine ufficiale)
python -m romm
