#!/bin/bash

source "$KIT_SRC_DIR/informs/check-internet-connection.sh"
source "$KIT_SRC_DIR/informs/check-system-dependencies.sh"
source "$KIT_SRC_DIR/informs/forbid-dev-on-main.sh"
source "$KIT_SRC_DIR/informs/summary-branch-status.sh"
source "$KIT_SRC_DIR/informs/check-for-updates.sh"