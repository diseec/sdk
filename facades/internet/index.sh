#!/bin/bash

# Optimized internet connectivity checker for Alpine Docker container
# This version is specifically designed for the Alpine Linux environment

# Source all required modules
source "$D_SDK_DIR/facades/internet/config.sh"
source "$D_SDK_DIR/facades/internet/network.sh"
source "$D_SDK_DIR/facades/internet/tests.sh"
source "$D_SDK_DIR/facades/internet/diagnosis.sh"
