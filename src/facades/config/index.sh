#!/bin/bash

source "$KIT_SRC_DIR/facades/config/functions.sh"

CONFIG_FILE=$(fac_con_get_config_file)

# Use yq if available, otherwise fallback
yaml_use_yq=$(fac_con_yaml_config_require_yq && echo "true" || echo "false")
