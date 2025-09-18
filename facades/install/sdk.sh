#!/bin/bash

sdk_fac_ins_sdk_process() {
    if [ "$IS_IN_SDK_CONTAINER" != "true" ]; then
        stdout -e "The 'patch' command works only on bench! (the $D_SDK_NAME container)"
        return 1
    fi

    local target_kit="$D_CONT_CTX_DIR/$D_SDK_LOCAL_RELATIVE_PATH"
    if [ -L "$target_kit" ]; then
        stdout -w "$target_kit is a symlink, most probably to a global $D_SDK_NAME installation. Aborting patch to avoid overwriting global sdk."
        return 1
    fi
     
    local version_specifier=$(_node -p "require('$D_CONT_CTX_DIR/package.json').dependencies?.['$D_SDK_NPM_PKG'] || require('$D_CONT_CTX_DIR/package.json').devDependencies['$D_SDK_NPM_PKG']")
    if [ $? -ne 0 ]; then
        stdout -e "Failed to read $D_SDK_NPM_PKG version from '$D_CONT_CTX_DIR/package.json'"
        return 1
    fi
    if [ -z "$version_specifier" ] || [ "$version_specifier" = "undefined" ]; then
        stdout -e "$D_SDK_NPM_PKG not found in '$D_CONT_CTX_DIR/package.json'"
        return 1
    fi

    local package_name="$D_SDK_NPM_PKG@$version_specifier"

    stdout -l "Fetching $package_name to $D_CONT_CTX_DIR .."
    
    local _tempdir=$(mktemp -d)
    local npm_output=$(cd $_tempdir && _npm install "$package_name")

    if [ $? -ne 0 ]; then
        stdout -e "Failed to fetch $package_name from registry." >&2
        echo "$npm_output" 
        rm -rf "$_tempdir"
        return 1
    fi

    rm -rf "$target_kit" 2>/dev/null 
    mkdir -p "$target_kit" 2>/dev/null

    cp -r "$_tempdir/$D_SDK_LOCAL_RELATIVE_PATH"/* "$target_kit"
    if [ $? -ne 0 ]; then
        stdout -e "Failed to copy $package_name to $target_kit" >&2
        rm -rf "$_tempdir"
        return 1
    fi

    fix_permissions "$target_kit"

    if [ ! -f "$D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME" ]; then
        stdout -l "No '$D_CLI_LOCAL_NAME' found in repo root. Applying template file..."
        cp "/$D_SDK_NAME/templates/$D_CLI_LOCAL_NAME" "$D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME";
    fi

    fix_permissions "$D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME"

    # if [ ! -f "$D_CONT_CTX_DIR/.gitignore" ]; then cp "/$D_SDK_NAME/templates/.gitignore" "$D_CONT_CTX_DIR/.gitignore"; fi
    local d_version="$(grep '"version"' "$D_CONT_CTX_DIR/$D_SDK_LOCAL_RELATIVE_PATH/package.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')"
    stdout -l "$D_SDK_NAME current version: $d_version"
}

sdk_fac_ins_sdk() {
    # docker pull image.registry.diseec.com/kit \
    #     --disable-content-trust > /dev/null 2>&1

    cli_core "$D_SDK_NAME" docker compose _ pull > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        stdout -e "Failed to pull latest $D_SDK_NAME image" >&2
        return 1
    fi

    cli_core "$D_SDK_NAME" stop > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        stdout -e "Failed to stop running $D_SDK_NAME container" >&2
        return 1
    fi

    cli_core "$D_SDK_NAME" run --quiet "/$D_SDK_NAME/$D_SDK_NAME" install function sdk_fac_ins_sdk_process
}

sdk_fac_ins_ensure_patched() {
    mark_ctx_only
    local is_forced="${D_GLOB_PATCH:-false}";
    local sdk_dir="$D_CTX_DIR/$D_SDK_LOCAL_RELATIVE_PATH";

    # Patch operation applied only either asked to or target project is missing the sdk
    if { [ _D_SDK_HAS_PATCHED != "true" ] && \
        [ -f "$D_CTX_DIR/$D_CLI_LOCAL_NAME" ] && \
        [ ! -f "$D_CTX_DIR/$D_SDK_NAME" ] && \
        { [ ! -d "$sdk_dir" ] || \
        [ -z "$(ls -A "$sdk_dir" 2> /dev/null)" ]; } } || \
        [ "$is_forced" = "true" ]; then

        local npm_update_sdk_global=$(_npm update -g $D_SDK_NPM_PKG)
        if [ $? -ne 0 ]; then
            echo "$npm_update_sdk_global"
            stdout -e "Patching global $D_SDK_NAME failed" >&2; return 1
        fi

        _D_SDK_HAS_PATCHED="true"
        sdk_fac_ins_sdk

        # abort if patch failed
        if [ $? -ne 0 ]; then
            stdout -e "Patching $D_SDK_NAME failed" >&2; return 1
        fi
    fi
}