#!/bin/bash

# =============================================================================
# PATH DISCOVERY UTILITIES
# =============================================================================
# Functions for discovering project structure and paths

sdk_boo_env_uti_cli_auto_discovery() {
    : ${HAS_DISCOVERED_CLI:=false}

    if [ "$D_D_CLI_EXECUTED" = "true" ]; then
        local starting_dir="$D_INI_PWD"
    else
        local starting_dir="$D_SDK_DIR"
    fi

    if [ "$HAS_DISCOVERED_CLI" = "true" ]; then return 0; fi

    # Canonicalize D_SDK_DIR
    starting_dir=$(cd "$1" 2>/dev/null && pwd) || {
        echo "Error: can't access '$1'" >&2
        return 1
    }

    # If we are in a SDK CLI context
    if [ "$D_SDK_CLI_EXECUTED" = "true" ]; then
        printf '%s\n' "$D_SDK_DIR" # SDK itself cannot be its own context
        HAS_DISCOVERED_CLI="true"
        return 0
    fi

    # # Do not lookup global SDK installation
    # if [ "$(npm root -g)/$D_SDK_NPM_PKG" = "$starting_dir" ]; then
    #     return 1
    # fi

    # # this breaks when a parent recursively do something on submodules then all of $D_CLI_LOCAL_NAME submodules point to the parent
    # if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
    #     printf '%s\n' "$D_CONT_CTX_DIR"
    #     return 0
    # fi

    local dir=$starting_dir
    while :; do
        if [ -f "$dir/$D_CLI_LOCAL_NAME" ]; then
            HAS_DISCOVERED_CLI="true"
            printf '%s\n' "$dir"
            return 0
        fi

        # If not found just silently skip and return null
        if [ "$dir" = "/" ]; then
            # logit -e "'$D_CLI_LOCAL_NAME' not found, try cd to project root" >&2
            # printf '%s\n' "$PWD"
            break
        fi

        dir=$(dirname -- "$dir")
    done
    
    # echo "Error: $D_CLI_LOCAL_NAME not found, looked up all levels from: $starting_dir" >&2
    # return 1
}

sdk_boo_env_uti_get_org_dir() {
    local org_dir="$HOME/$D_ORG_NAME"
    if [ ! -d "$org_dir" ]; then 
        mkdir -p "$org_dir"
    fi
    echo "$org_dir"
}

sdk_boo_env_uti_get_cache_dir() {
    local org_cache_dir="$(sdk_boo_env_uti_get_org_dir)/.cache"
    if [ ! -d "$org_cache_dir" ]; then 
        mkdir -p "$org_cache_dir"
    fi
    echo "$org_cache_dir"
}
