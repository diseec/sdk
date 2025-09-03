#!/bin/bash

kit_fac_act_patch() {
    set -e

    target_kit="$TARGET_MOUNTED_DIR/$KIT_RELATIVE_PATH"

    if [ -L "$target_kit" ]; then
        logit -w "$target_kit is a symlink, most probably to a global kit installation. Aborting patch to avoid overwriting global kit."
        return 1
    fi

    VERSION_SPECIFIER=$(_node -p "require('$TARGET_MOUNTED_DIR/package.json').dependencies?.['$KIT_PACKAGE_NAME'] || require('$TARGET_MOUNTED_DIR/package.json').devDependencies['$KIT_PACKAGE_NAME']")

    if [ -z "$VERSION_SPECIFIER" ]; then
        logit -e "$KIT_PACKAGE_NAME not found in '$TARGET_MOUNTED_DIR/package.json'. $PWD"
        exit 1
    fi

    package_name="$KIT_PACKAGE_NAME@$VERSION_SPECIFIER"

    logit -l "Fetching $package_name from registry .."
    TMPDIR=$(mktemp -d)
    (cd $TMPDIR && _npm install "$package_name")

    logit -l "Patching $package_name to $TARGET_MOUNTED_DIR .."
    rm -rf "$target_kit" 2>/dev/null 
    mkdir -p "$target_kit" 2>/dev/null
    cp -r "$TMPDIR/$KIT_RELATIVE_PATH"/* "$target_kit"

    if [ ! -f "$TARGET_MOUNTED_DIR/cli" ]; then
        logit -l "No 'cli' found in repo root. Applying template file..."
        cp "/$KIT_NAME/templates/cli" "$TARGET_MOUNTED_DIR/cli";
    fi

    # if [ ! -f "$TARGET_MOUNTED_DIR/.gitignore" ]; then cp "/$KIT_NAME/templates/.gitignore" "$TARGET_MOUNTED_DIR/.gitignore"; fi
    logit -l "$KIT_NAME patched for: $package_name"
}