#!/bin/bash

# Main entry point for the internet connectivity checker

# Source all required modules
source "$KIT_SRC_DIR/facades/internet/os_detection.sh"
source "$KIT_SRC_DIR/facades/internet/math_utils.sh"
source "$KIT_SRC_DIR/facades/internet/config.sh"
source "$KIT_SRC_DIR/facades/internet/logging.sh"
source "$KIT_SRC_DIR/facades/internet/network.sh"
source "$KIT_SRC_DIR/facades/internet/basic_tests.sh"
source "$KIT_SRC_DIR/facades/internet/dns_tests.sh"
source "$KIT_SRC_DIR/facades/internet/site_tests.sh"
source "$KIT_SRC_DIR/facades/internet/quality_tests.sh"
source "$KIT_SRC_DIR/facades/internet/diagnosis.sh"
