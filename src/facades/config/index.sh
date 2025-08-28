#!/bin/bash

source "$KIT_SRC_DIR/facades/config/functions.sh"

CONFIG_FILE=$(get_config_file)

# Use yq if available, otherwise fallback
yaml_use_yq=$(yaml_config_require_yq && echo "true" || echo "false")
