#!/bin/bash

source_once "$KIT_SRC_DIR/facades/submodule/index.sh"

# Unified submodule management for packages and services
# Uses structure: command submodule_type/path/to/reponame [options] [arguments]

# Initialize variables
type=""
target_dir=""
repo_name=""
command=""
command_args=()
relative_path=""
submodule_path=""

# Function to extract information from the path format
src_fac_sub_parse_path_format() {
    local full_path="$1"
    
    # Split the path into components
    IFS='/' read -ra path_components <<< "$full_path"
    
    # Must have at least 2 segments (type/reponame)
    if [[ ${#path_components[@]} -lt 2 ]]; then
        logit -e "Invalid path format. Must be at least 'type/reponame'"
        return 1
    fi
    
    # Extract type (first component)
    type="${path_components[0]}"
    
    # Extract repo name (last component)
    repo_name="${path_components[${#path_components[@]}-1]}"
    
    # Build the relative path (everything except the repo name)
    local path_prefix=()
    for ((i=0; i<${#path_components[@]}-1; i++)); do
        path_prefix+=("${path_components[$i]}")
    done
    
    # Join the path components for the target directory
    target_dir=$(IFS='/'; echo "${path_prefix[*]}")
    
    # The full submodule path includes the repo name
    submodule_path="$target_dir/$repo_name"
    
    return 0
}

# Parse command line arguments
if [[ $# -gt 0 ]]; then
    # First argument is the command
    command="$1"
    shift

    # Second argument should be the path if available
    if [[ $# -gt 0 && "$1" == */* ]]; then
        src_fac_sub_parse_path_format "$1" || exit 1
        shift
    fi
    
    # Remaining arguments are command args
    command_args=("$@")
fi

# Validate inputs
if [[ -z "$command" ]]; then
    logit -e "No command specified"
    display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[D] submodule <command> submodule_type/path/to/reponame [options] [arguments]" \
        "" "" "$(ansi "1;90" "$(capitalize 'For more information')")" "" \
        "    Run 'D submodule help' for detailed usage information"
    exit 1
elif [[ "$command" != "help" && "$command" != "--help" && "$command" != "-h" && "$command" != "list" && "$command" != "ls" && "$command" != "lis" ]]; then
    # Most commands require a path specification
    if [[ -z "$type" || -z "$repo_name" ]]; then
        logit -e "Missing path specification. Format should be: D submodule $command type/path/to/reponame [args]"
        exit 1
    fi
fi

# Ensure target directory exists if specified
if [[ -n "$target_dir" ]]; then
    mkdir -p "$target_dir"
fi

case $command in
    add)
        if [[ -z "$repo_name" ]]; then
            logit -e "Repository name is required for add command"
            exit 1
        fi
        
        logit "Adding repository '$repo_name' to $target_dir/ as type '$type'"
        set -e
        _git submodule add https://$REPO_HUB_URL/$repo_name.git $submodule_path
        _git submodule update --init --recursive
        ;;

    rem|remove|rm)
        if [[ -z "$repo_name" ]]; then
            logit -e "Repository name is required for remove command"
            exit 1
        fi
        
        confirm "Are you sure you want to remove '$repo_name' from $target_dir/?" \
            set -e; \
            _git submodule deinit -f -- $submodule_path; \
            rm -rf .git/modules/$submodule_path; \
            _git rm -f $submodule_path;
        ;;

    upd|update)
        if [[ -n "$repo_name" ]]; then
            logit "Updating submodule at $submodule_path"
            _git submodule update --remote -- $submodule_path
        else
            target_to_update=${target_dir:-"."}
            logit "Updating all submodules in $target_to_update"
            _git submodule update --remote --merge -- $target_to_update
        fi
        ;;

    lin|link)
        if [[ -z "$repo_name" ]]; then
            # Interactive mode if no specific repo is given
            available_packages=$(ls packages 2>/dev/null || echo '')
            if [[ -z "$available_packages" ]]; then
                logit -e "No packages found in packages/"
                exit 1
            fi
            logit --ansi="35" --icon="PACKAGES:" "$available_packages"
            read -p "$(logit --ansi="35" --icon="?" "Select a package to link: ")" selected_package
            if [[ -n "$selected_package" ]]; then
                repo_name="$selected_package"
                submodule_path="packages/$repo_name"
            else
                exit 1
            fi
        elif [[ "$type" != "package" && "$type" != "packages" ]]; then
            logit -w "Linking is typically used with packages. Proceeding anyway with $submodule_path"
        fi
        
        if [[ -d "$submodule_path" ]]; then
            logit "Linking package at $submodule_path"
            _npm link ./$submodule_path
        else
            logit -e "Directory $submodule_path does not exist"
            exit 1
        fi
        ;;

    lis|list|ls)
        search_dir=${target_dir:-"."}
        if [[ -d "$search_dir" ]]; then
            if [[ -n "$repo_name" ]]; then
                # List contents of the specific repo
                if [[ -d "$submodule_path" ]]; then
                    logit --ansi="34" --icon="CONTENTS of $submodule_path:" "\n$(ls -la $submodule_path 2>/dev/null || echo 'Empty directory')"
                else
                    logit -e "Directory $submodule_path does not exist"
                    exit 1
                fi
            else
                # List all items in the target directory
                type_display=${type:-"item"}
                logit --ansi="34" --icon="${type_display^^}S in $search_dir:" "\n$(ls $search_dir 2>/dev/null || echo 'No items found')"
            fi
        else
            logit -w "Directory $search_dir does not exist"
        fi
        ;;

    hel|help|--help|-h) display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[D] submodule <command> submodule_type/path/to/reponame [options] [arguments]" \
        "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$ORG_NAME/$KIT_NAME")")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Commands')")" "" \
        "    add <path>               " "Add a new submodule from repository" \
        "    rem|remove|rm <path>     " "Remove an existing submodule" \
        "    upd|update [path]        " "Update specific or all submodules" \
        "    lin|link <path>          " "Link local package for development" \
        "    lis|list|ls [path]       " "List submodules or contents" \
        "" "" "$(ansi "1;90" "$(capitalize 'Path Format')")" "" \
        "    submodule_type/path/repo " "Format: type/path/to/repository" \
        "                             " "$(ansi "2;90" "Where type is typically 'package', 'service', etc.")" \
        "                             " "$(ansi "2;90" "The path components between type and repo are optional")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Examples')")" "" \
        "    D submodule add package/my-package          " "Add a package submodule" \
        "    D submodule add service/my-service/api      " "Add with nested path" \
        "    D submodule remove package/my-package       " "Remove a submodule" \
        "    D submodule update service/my-service       " "Update specific submodule" \
        "    D submodule update package                  " "Update all packages" \
        "    D submodule ls package/my-package           " "List contents of submodule"
    ;;
    *)
        if [[ -n "$submodule_path" && -d "$submodule_path" && -f "$submodule_path/cli" ]]; then
            # If the submodule has a cli script, run it with the command as first argument
            "$submodule_path/cli" "${command_args[@]}"
        elif [[ -n "$target_dir" && -d "$target_dir" && -f "$target_dir/cli" ]]; then
            # If the target directory has a cli script, run it
            "$target_dir/cli" "${command_args[@]}"
        else
            logit -e "Unknown command: '$command'"
            display_help "" "" \
                "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[D] submodule <command> submodule_type/path/to/reponame [options] [arguments]" \
                "" "" "$(ansi "1;90" "$(capitalize 'For more information')")" "" \
                "    Run 'D submodule help' for detailed usage information"
            exit 1
        fi
    ;;
esac
