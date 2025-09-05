#!/bin/bash

sdk_fac_git_cmd_release() {
    local TAG="v$(date +%Y%m%d%H%M%S)"
    # git checkout main
    # git pull origin main
    # git tag -a $TAG -m "Release $TAG"
    # git push origin $TAG
}

