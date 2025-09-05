#!/bin/bash

sdk_fac_set_sdk() {
    set -e

    # docker pull image.registry.diseec.com/kit \
    #     --disable-content-trust > /dev/null 2>&1
    cli_main docker compose _ pull; > /dev/null 2>&1

    sdk_fac_set_sdk_process() {
        if [ "$IS_IN_SDK_CONTAINER" != "true" ]; then
            logit -e "The 'patch' command works only on bench! (the sdk container)"; return 1; 
        fi

        target_kit="$D_CTX_DIR_CONTAINER/$D_SDK_NPM_PATH"

        if [ -L "$target_kit" ]; then
            logit -w "$target_kit is a symlink, most probably to a global sdk installation. Aborting patch to avoid overwriting global sdk."
            return 1
        fi

        VERSION_SPECIFIER=$(_node -p "require('$D_CTX_DIR_CONTAINER/package.json').dependencies?.['$D_SDK_NPM_PKG'] || require('$D_CTX_DIR_CONTAINER/package.json').devDependencies['$D_SDK_NPM_PKG']")

        if [ -z "$VERSION_SPECIFIER" ]; then
            logit -e "$D_SDK_NPM_PKG not found in '$D_CTX_DIR_CONTAINER/package.json'. $PWD"
            exit 1
        fi

        package_name="$D_SDK_NPM_PKG@$VERSION_SPECIFIER"

        logit -l "Fetching $package_name from registry .."
        TMPDIR=$(mktemp -d)
        (cd $TMPDIR && _npm install "$package_name")

        logit -l "Patching $package_name to $D_CTX_DIR_CONTAINER .."
        rm -rf "$target_kit" 2>/dev/null 
        mkdir -p "$target_kit" 2>/dev/null
        cp -r "$TMPDIR/$D_SDK_NPM_PATH"/* "$target_kit"

        if [ ! -f "$D_CTX_DIR_CONTAINER/$D_CLI_LOCAL_NAME" ]; then
            logit -l "No '$D_CLI_LOCAL_NAME' found in repo root. Applying template file..."
            cp "/$D_SDK_NAME/templates/$D_CLI_LOCAL_NAME" "$D_CTX_DIR_CONTAINER/$D_CLI_LOCAL_NAME";
        fi

        # if [ ! -f "$D_CTX_DIR_CONTAINER/.gitignore" ]; then cp "/$D_SDK_NAME/templates/.gitignore" "$D_CTX_DIR_CONTAINER/.gitignore"; fi
        logit -l "$D_SDK_NAME patched for: $package_name"
    }

    safely && sdk_fac_set_sdk_process
}

sdk_fac_set_ensure_patched() {
    local is_forced="$1";
    local ctx_dir="$2";
    local sdk_dir="$ctx_dir/$D_SDK_NPM_PATH";

    # Patch operation applied only either asked to or target project is missing the sdk
    if { [ _HAS_PATCHED != "true" ] && \
        [ -f "$ctx_dir/$D_CLI_LOCAL_NAME" ] && \
        [ ! -f "$ctx_dir/$D_CLI_GLOBAL_NAME" ] && \
        { [ ! -d "$sdk_dir" ] || \
        [ -z "$(ls -A "$sdk_dir" 2> /dev/null)" ]; } } || \
        [ "$is_forced" = "true" ]; then

        _HAS_PATCHED="true"
        main_cli sdk patch

        # abort if patch failed
        if [ $? -ne 0 ]; then
            logit -e "Patching $D_SDK_NAME failed" >&2; exit 1
        fi
    fi
}