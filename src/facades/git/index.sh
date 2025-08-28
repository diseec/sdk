#!/bin/bash

source "$KIT_SRC_DIR/facades/workspace/index.sh"
source "$KIT_SRC_DIR/facades/ai/index.sh"

source "$KIT_SRC_DIR/facades/git/exceptions.sh"
source "$KIT_SRC_DIR/facades/git/cmds/pull.sh"
source "$KIT_SRC_DIR/facades/git/cmds/commit-push-pr.sh"
source "$KIT_SRC_DIR/facades/git/cmds/checkout.sh"
source "$KIT_SRC_DIR/facades/git/cmds/commit.sh"
source "$KIT_SRC_DIR/facades/git/cmds/push.sh"
source "$KIT_SRC_DIR/facades/git/cmds/pr.sh"
source "$KIT_SRC_DIR/facades/git/cmds/log.sh"
source "$KIT_SRC_DIR/facades/git/cmds/release.sh"
