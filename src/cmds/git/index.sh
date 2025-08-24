#!/bin/bash

. $KIT_SRC_DIR/cmds/workspace/index.sh
. $KIT_SRC_DIR/cmds/git/exceptions.sh
. $KIT_SRC_DIR/cmds/git/checkout.sh
. $KIT_SRC_DIR/cmds/git/pull.sh
. $KIT_SRC_DIR/cmds/git/commit.sh
. $KIT_SRC_DIR/cmds/git/push.sh
. $KIT_SRC_DIR/cmds/git/pr.sh
. $KIT_SRC_DIR/cmds/git/commit-push-pr.sh
. $KIT_SRC_DIR/cmds/git/insight.sh
. $KIT_SRC_DIR/cmds/git/release.sh

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments
