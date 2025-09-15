#!/bin/bash

source_once "$D_SDK_DIR/facades/submodule/index.sh"

# Unified submodule management for packages and services

c=$1; shift; case $c in

    # Feature 
    # TODO: to centralize the selected modules use docker-compose file instead(!?)
    sel|select) sdk_fac_sub_fea_act_select "$@" ;;
    fac|foreach_active) sdk_fac_sub_fea_act_foreach_selected_module "$@" ;;

    sta|status) sdk_fac_sub_fea_act_status "$@" ;;
    for|foreach) sdk_fac_sub_fea_foreach_submodule "$@" ;;
    act|actives) sdk_fac_sub_fea_act_get_selected_module_paths "$@" ;;

    # Core submodule commands
    add)
        local submodule_path="$1"
        read type repo_name type_dir <<< "$(sdk_fac_sub_parse_path_format "$submodule_path")"
        stdout "Adding repository '$repo_name' to $type_dir/ as type '$type'"
        set -e
        _git submodule add https://$D_REPOSITORY_URL/$repo_name.git "$submodule_path"
        _git submodule update --init --recursive
        ;;

    rem|remove|rm)
        local submodule_path="$1"
        read type repo_name type_dir <<< "$(sdk_fac_sub_parse_path_format "$submodule_path")"
        if confirm "Are you sure you want to remove '$repo_name' from '$type_dir/'?"; then
            set -e
            _git submodule deinit -f -- "$submodule_path"
            rm -rf .git/modules/"$submodule_path"
            _git rm -f "$submodule_path"
        fi
        ;;

    upd|update)
        local submodule_path="$1"
        read type repo_name type_dir <<< "$(sdk_fac_sub_parse_path_format "$submodule_path")"
        if [[ -n "$repo_name" ]]; then
            stdout "Updating submodule at $submodule_path"
            _git submodule update --remote -- "$submodule_path"
        else
            # todo
            target_to_update=${type_dir:-"."}
            stdout "Updating all submodules in $target_to_update"
            _git submodule update --remote --merge -- "$target_to_update"
        fi
        ;;

    lin|link)
        local submodule_path="$1"
        read type repo_name type_dir <<< "$(sdk_fac_sub_parse_path_format "$submodule_path")"
        if [[ -z "$repo_name" ]]; then
            # Interactive mode if no specific repo is given
            available_packages=$(ls packages 2>/dev/null || echo '')
            if [[ -z "$available_packages" ]]; then
                stdout -e "No packages found in packages/"
                return 1
            fi
            stdout --ansi="35" --icon="PACKAGES:" "$available_packages"
            stdin selected_package "Select a package to link:" 
            if [[ -n "$selected_package" ]]; then
                repo_name="$selected_package"
                submodule_path="packages/$repo_name"
            else
                return 1
            fi
        elif [[ "$type" != "package" && "$type" != "packages" ]]; then
            stdout -w "Linking is typically used with packages. Proceeding anyway with $submodule_path"
        fi
        
        if [[ -d "$submodule_path" ]]; then
            stdout "Linking package at $submodule_path"
            _npm link ./$submodule_path
        else
            stdout -e "Directory $submodule_path does not exist"
            return 1
        fi
        ;;

    lis|list|ls)
        local submodule_path="$1"
        read type repo_name type_dir <<< "$(sdk_fac_sub_parse_path_format "$submodule_path")"
        search_dir=${type_dir:-"."}
        if [[ -d "$search_dir" ]]; then
            if [[ -n "$repo_name" ]]; then
                # List contents of the specific repo
                if [[ -d "$submodule_path" ]]; then
                    stdout --ansi="34" --icon="CONTENTS of $submodule_path:" "\n$(ls -la $submodule_path 2>/dev/null || echo 'Empty directory')"
                else
                    stdout -e "Directory $submodule_path does not exist"
                    return 1
                fi
            else
                # List all items in the target directory
                type_display=${type:-"item"}
                stdout --ansi="34" --icon="${type_display^^}S in $search_dir:" "\n$(ls $search_dir 2>/dev/null || echo 'No items found')"
            fi
        else
            stdout -w "Directory $search_dir does not exist"
        fi
        ;;

    hel|help|--help|-h) display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "$D_CLI_GLOBAL_NAME submodule <command> <type>/[path]/<reponame> [options] [arguments]" \
        "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Features')")" "" \
        "    $(ansi "1;2;90" "$(capitalize 'Active Modules')")" "" \
        "    sse|select               " "Activate submodules for workspace" \
        "    sst|status               " "Show active submodules in workspace" \
        "" "" "$(ansi "1;90" "$(capitalize 'Commands')")" "" \
        "    add <path>               " "Add a new submodule from repository" \
        "    rem|remove|rm <path>     " "Remove an existing submodule" \
        "    upd|update [path]        " "Update specific or all submodules" \
        "    lin|link <path>          " "Link local package for development" \
        "    lis|list|ls [path]       " "List submodules or contents" \
        "" "" "    $(ansi "1;2;90" "$(capitalize 'Path Format')")              " "type/path/to/repository" \
        "                             " "$(ansi "2;90" "Where type is typically 'package', 'service', etc.")" \
        "                             " "$(ansi "2;90" "The path components between type and repo are optional")" \
        "    $(ansi "1;2;90" "$(capitalize 'Examples')")              " "" \
        "    $(ansi "2;90" "$D_CLI_GLOBAL_NAME submodule add package/my-package")          " "$(ansi "2;90" "Add a package submodule")" \
        "    $(ansi "2;90" "$D_CLI_GLOBAL_NAME submodule add service/my-service/api")      " "$(ansi "2;90" "Add with nested path")" \
        "    $(ansi "2;90" "$D_CLI_GLOBAL_NAME submodule remove package/my-package")       " "$(ansi "2;90" "Remove a submodule")" \
        "    $(ansi "2;90" "$D_CLI_GLOBAL_NAME submodule update service/my-service")       " "$(ansi "2;90" "Update specific submodule")" \
        "    $(ansi "2;90" "$D_CLI_GLOBAL_NAME submodule update package")                  " "$(ansi "2;90" "Update all packages")" \
        "    $(ansi "2;90" "$D_CLI_GLOBAL_NAME submodule ls package/my-package")           " "$(ansi "2;90" "List contents of submodule")"
    ;;
    fun|function) "$@" ;;
    *) if [ ! -z "$c" ]; then stdout -e "submodule: Unknown command: '$c'"; fi ;;
esac
