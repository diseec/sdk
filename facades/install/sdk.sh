#!/bin/bash

sdk_fac_ins_sdk_process() {
    stdout -d "Entering sdk_fac_ins_sdk_process function"
    processing_start "BRAILLE_MIXED"

    if [ "$IS_IN_SDK_CONTAINER" != "true" ]; then
        stdout -d "Not in SDK container, aborting"
        stdout -e "The 'patch' command works only on bench! (the $D_SDK_NAME container)"
        return 1
    fi

    local target_kit="$D_CONT_CTX_DIR/$D_SDK_LOCAL_RELATIVE_PATH"
    stdout -d "Target kit path: $target_kit"
    if [ -L "$target_kit" ]; then
        stdout -d "Target kit is a symlink, aborting"
        stdout -w "$target_kit is a symlink, most probably to a global $D_SDK_NAME installation. Aborting patch to avoid overwriting global sdk."
        return 1
    fi
     
    stdout -d "Getting version specifier from package.json"
    local version_specifier=$(_node -p "require('$D_CONT_CTX_DIR/package.json').dependencies?.['$D_SDK_NPM_PKG'] || require('$D_CONT_CTX_DIR/package.json').devDependencies['$D_SDK_NPM_PKG']")
    if [ $? -ne 0 ]; then
        stdout -d "Failed to read version from package.json"
        stdout -e "Failed to read $D_SDK_NPM_PKG version from '$D_CONT_CTX_DIR/package.json'"
        return 1
    fi
    if [ -z "$version_specifier" ] || [ "$version_specifier" = "undefined" ]; then
        stdout -d "Package not found in package.json: $D_SDK_NPM_PKG"
        stdout -e "$D_SDK_NPM_PKG not found in '$D_CONT_CTX_DIR/package.json'"
        return 1
    fi
    stdout -d "Version specifier found: $version_specifier"

    local package_name="$D_SDK_NPM_PKG@$version_specifier"
    stdout -d "Package name: $package_name"

    stdout -l --processing "Fetching $package_name to $D_CONT_CTX_DIR"
    
    local _tempdir=$(mktemp -d)
    stdout -d "Created temp directory: $_tempdir"
    stdout -d "Running npm install for $package_name"
    local npm_output=$(cd $_tempdir && _npm install "$package_name")

    if [ $? -ne 0 ]; then
        stdout -d "npm install failed"
        stdout -e "Failed to fetch $package_name from registry." >&2
        echo "$npm_output" 
        rm -rf "$_tempdir"
        return 1
    fi
    stdout -d "npm install successful"

    stdout -d "Removing existing target kit: $target_kit"
    rm -rf "$target_kit" 2>/dev/null 
    stdout -d "Creating target kit directory"
    mkdir -p "$target_kit" 2>/dev/null

    stdout -d "Copying files from $_tempdir/$D_SDK_LOCAL_RELATIVE_PATH to $target_kit"
    cp -r "$_tempdir/$D_SDK_LOCAL_RELATIVE_PATH"/* "$target_kit"
    if [ $? -ne 0 ]; then
        stdout -d "Copy operation failed"
        stdout -e "Failed to copy $package_name to $target_kit" >&2
        rm -rf "$_tempdir"
        return 1
    fi
    stdout -d "Copy operation successful"

    stdout -d "Fixing permissions for $target_kit"
    fix_permissions "$target_kit"

    stdout -d "Checking for CLI file in repo root: $D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME"
    if [ ! -f "$D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME" ]; then
        stdout -d "CLI file not found, applying template"
        stdout -l --processing "No '$D_CLI_LOCAL_NAME' found in repo root. Applying template file"
        cp "/$D_SDK_NAME/templates/$D_CLI_LOCAL_NAME" "$D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME";
        stdout -d "Template applied from /$D_SDK_NAME/templates/$D_CLI_LOCAL_NAME"
    else
        stdout -d "CLI file already exists, not overwriting"
    fi

    stdout -d "Fixing permissions for $D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME"
    fix_permissions "$D_CONT_CTX_DIR/$D_CLI_LOCAL_NAME"

    # if [ ! -f "$D_CONT_CTX_DIR/.gitignore" ]; then cp "/$D_SDK_NAME/templates/.gitignore" "$D_CONT_CTX_DIR/.gitignore"; fi
    stdout -d "Getting SDK version from package.json"
    local d_version="$(grep '"version"' "$D_CONT_CTX_DIR/$D_SDK_LOCAL_RELATIVE_PATH/package.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')"
    stdout -d "SDK version detected: $d_version"
    stdout -l "$D_SDK_NAME patched to version $d_version"
    stdout -d "sdk_fac_ins_sdk_process function completed successfully"
}

sdk_fac_ins_sdk() {
    stdout -d "Entering sdk_fac_ins_sdk function"
    processing_start "BRAILLE_MIXED"

    # docker pull image.registry.diseec.com/kit \
    #     --disable-content-trust > /dev/null 2>&1

    stdout -d "Pulling latest SDK docker image"
    # local pull_output=$(cli_core "$D_SDK_NAME" docker compose _ pull &>&1)
    local pull_output=$(cli_core "$D_SDK_NAME" docker compose _ pull)
    if [ $? -ne 0 ]; then
        echo $pull_output
        stdout -e "Failed to pull latest $D_SDK_NAME image" >&2
        return 1
    fi
    stdout -d "Successfully pulled latest SDK image"

    stdout -d "Stopping any running SDK container"
    cli_core "$D_SDK_NAME" stop > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        stdout -d "Failed to stop running SDK container"
        stdout -e "Failed to stop running $D_SDK_NAME container" >&2
        return 1
    fi
    stdout -d "Successfully stopped SDK container"

    processing_stop

    stdout -d "Running sdk_fac_ins_sdk_process function in SDK container"
    cli_core "$D_SDK_NAME" run --quiet "/$D_SDK_NAME/$D_SDK_NAME" install function sdk_fac_ins_sdk_process
}

sdk_fac_ins_ensure_patched() {
    stdout -d "Entering sdk_fac_ins_ensure_patched function"
    mark_ctx_only

    local is_forced="${D_PATCH:-false}";
    stdout -d "Force patch: $is_forced"
    local sdk_dir="$D_CTX_DIR/$D_SDK_LOCAL_RELATIVE_PATH";
    stdout -d "SDK directory: $sdk_dir"

    # Patch operation applied only either asked to or target project is missing the sdk
    stdout -d "Checking if patch is needed"
    stdout -d "Has already patched: ${_D_SDK_HAS_PATCHED:-false}"
    stdout -d "CLI file exists: $([ -f "$D_CTX_DIR/$D_CLI_LOCAL_NAME" ] && echo "true" || echo "false")"
    stdout -d "SDK file exists: $([ -f "$D_CTX_DIR/$D_SDK_NAME" ] && echo "true" || echo "false")"
    stdout -d "SDK dir exists: $([ -d "$sdk_dir" ] && echo "true" || echo "false")"
    stdout -d "SDK dir empty: $([ -z "$(ls -A "$sdk_dir" 2> /dev/null)" ] && echo "true" || echo "false")"
    if { [ _D_SDK_HAS_PATCHED != "true" ] && \
        [ -f "$D_CTX_DIR/$D_CLI_LOCAL_NAME" ] && \
        [ ! -f "$D_CTX_DIR/$D_SDK_NAME" ] && \
        { [ ! -d "$sdk_dir" ] || \
        [ -z "$(ls -A "$sdk_dir" 2> /dev/null)" ]; } } || \
        [ "$is_forced" = "true" ]; then
        stdout -d "Patch is needed"

        stdout -d "Updating global SDK package"
        local npm_update_sdk_global=$(_npm update -g $D_SDK_NPM_PKG)
        if [ $? -ne 0 ]; then
            stdout -d "Global update failed"
            echo "$npm_update_sdk_global"
            stdout -e "Patching global $D_SDK_NAME failed" >&2; return 1
        fi
        stdout -d "Global update successful"
        
        stdout -d "Setting _D_SDK_HAS_PATCHED to true"
        _D_SDK_HAS_PATCHED="true"

        stdout -d "Checking for package.json and SDK package dependency"
        if [ -f "$D_CTX_DIR/package.json" ] && \
           grep -q "\"$D_SDK_NPM_PKG\"" "$D_CTX_DIR/package.json"; then
            stdout -d "Found SDK package in dependencies, patching"
            sdk_fac_ins_sdk
        else
            stdout -d "No SDK dependency found in package.json, skipping patch"
            stdout -w "No dep definition, skipping patching; in: $D_CTX_DIR"
        fi

        # abort if patch failed
        if [ $? -ne 0 ]; then
            stdout -d "Patching SDK failed"
            stdout -e "Patching $D_SDK_NAME failed" >&2; return 1
        fi
        stdout -d "Patching SDK successful"
    else
        stdout -d "No patching needed"
    fi
    stdout -d "sdk_fac_ins_ensure_patched function completed"
}