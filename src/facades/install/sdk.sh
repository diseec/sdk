#!/bin/bash

src_fac_set_sdk() {
    set -e

    # docker pull image.registry.diseec.com/kit \
    #     --disable-content-trust > /dev/null 2>&1
    cli_main docker compose _ pull; > /dev/null 2>&1

    src_fac_set_sdk_process() {
        if [ "$IS_IN_SDK_CONTAINER" != "true" ]; then
            logit -e "The 'patch' command works only on bench! (the sdk container)"; return 1; 
        fi

        target_kit="$WORK_DIR_CONTAINER/$SDK_RELATIVE_PATH"

        if [ -L "$target_kit" ]; then
            logit -w "$target_kit is a symlink, most probably to a global sdk installation. Aborting patch to avoid overwriting global sdk."
            return 1
        fi

        VERSION_SPECIFIER=$(_node -p "require('$WORK_DIR_CONTAINER/package.json').dependencies?.['$SDK_PACKAGE_NAME'] || require('$WORK_DIR_CONTAINER/package.json').devDependencies['$SDK_PACKAGE_NAME']")

        if [ -z "$VERSION_SPECIFIER" ]; then
            logit -e "$SDK_PACKAGE_NAME not found in '$WORK_DIR_CONTAINER/package.json'. $PWD"
            exit 1
        fi

        package_name="$SDK_PACKAGE_NAME@$VERSION_SPECIFIER"

        logit -l "Fetching $package_name from registry .."
        TMPDIR=$(mktemp -d)
        (cd $TMPDIR && _npm install "$package_name")

        logit -l "Patching $package_name to $WORK_DIR_CONTAINER .."
        rm -rf "$target_kit" 2>/dev/null 
        mkdir -p "$target_kit" 2>/dev/null
        cp -r "$TMPDIR/$SDK_RELATIVE_PATH"/* "$target_kit"

        if [ ! -f "$WORK_DIR_CONTAINER/cli" ]; then
            logit -l "No 'cli' found in repo root. Applying template file..."
            cp "/$SDK_NAME/templates/cli" "$WORK_DIR_CONTAINER/cli";
        fi

        # if [ ! -f "$WORK_DIR_CONTAINER/.gitignore" ]; then cp "/$SDK_NAME/templates/.gitignore" "$WORK_DIR_CONTAINER/.gitignore"; fi
        logit -l "$SDK_NAME patched for: $package_name"
    }

    safely && src_fac_set_sdk_process
}

src_fac_set_ensure_patched() {
    local is_forced="$1";
    local work_dir="$2";
    local sdk_dir="$work_dir/$SDK_RELATIVE_PATH";

    # Patch operation applied only either asked to or target project is missing the sdk
    if { [ _HAS_PATCHED != "true" ] && \
        [ -f "$work_dir/cli" ] && \
        [ ! -f "$work_dir/D" ] && \
        { [ ! -d "$sdk_dir" ] || \
        [ -z "$(ls -A "$sdk_dir" 2> /dev/null)" ]; } } || \
        [ "$is_forced" = "true" ]; then

        _HAS_PATCHED="true"
        main_cli sdk patch

        # abort if patch failed
        if [ $? -ne 0 ]; then
            logit -e "Patching $SDK_NAME failed" >&2; exit 1
        fi
    fi
}