#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

source "$D_SDK_DIR/facades/docker/up-development.sh"
source "$D_SDK_DIR/facades/docker/up-production.sh"
source "$D_SDK_DIR/facades/docker/execute.sh"
