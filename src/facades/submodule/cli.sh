#!/bin/bash

# Unified submodule management for packages and services
# Default behavior follows git submodule conventions

# Parse options
type=""
target_dir=""
repo_name=""
command=""

# Function to show help
show_help() {
    display_help "" "" \
        "$(color 33 'SUBMODULE')" "" \
        "$(color 30 'Unified submodule management for packages and services\n')" "" \
        "$(color 30 'Usage:    cli submodule [options] <command> [arguments]\n')" "" \
        "$(color 30 'Options:')" "" \
        "  --type <package|service>   " "Specify submodule type (default: auto-detect from target dir)" \
        "  --dir <directory>          " "Target directory (default: packages/ or services/ based on type)" \
        "" "" "$(color 30 'Commands:')" "" \
        "  add <name>                 " "Add submodule from repository" \
        "  rem|remove|rm <name>       " "Remove submodule" \
        "  upd|update                 " "Update all submodules" \
        "  run                        " "Run command in service container (services only)" \
        "  lin|link                   " "Link local package for development (packages only)" \
        "" "" "$(color 30 'Examples:')" "" \
        "  cli submodule add my-package                    " "Adds to packages/" \
        "  cli submodule --type service add my-service     " "Adds to services/" \
        "  cli submodule --dir custom/path add my-repo     " "Custom directory" \
        "  cli submodule remove my-package                 " "" \
        "  cli submodule update                             " "" \
        ""
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            type="$2"
            shift 2
            ;;
        --dir)
            target_dir="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$command" ]]; then
                command="$1"
            else
                repo_name="$1"
            fi
            shift
            ;;
    esac
done

# Auto-detect type and directory if not specified
if [[ -z "$type" && -z "$target_dir" ]]; then
    # Default to submodules
    type="submodule"
    target_dir="submodules"
elif [[ -n "$type" && -z "$target_dir" ]]; then
    case $type in
        submodule) target_dir="submodules" ;;
        package) target_dir="packages" ;;
        service) target_dir="services" ;;
        *) message 41 "!" "Unknown type: $type. Use 'package' or 'service'" exit 1 ;;
    esac
elif [[ -z "$type" && -n "$target_dir" ]]; then
    # Auto-detect type from directory
    case $target_dir in
        submodules|submodules/*) type="submodule" ;;
        packages|packages/*) type="package" ;;
        services|services/*) type="service" ;;
        *) type="custom" ;;
    esac
fi

# Ensure target directory exists
mkdir -p "$target_dir"

case $command in
    add)
        if [[ -z "$repo_name" ]]; then
            message 41 "!" "Repository name is required for add command"
            exit 1
        fi
        
        message "Adding $type '$repo_name' to $target_dir/ .."
        set -e
        _git submodule add https://$REPO_HUB_URL/$repo_name.git $target_dir/$repo_name
        _git submodule update --init --recursive
        ;;

    run)
        if [[ "$type" != "service" ]]; then
            message 41 "!" "Run command is only available for services"
            exit 1
        fi
        
        services=$(docker compose config --services)
        message "45" "SERVICES:" "\n$services"
        read -p "$(message 45 "?" "Specify a service to run:")" service
        $CLI_MAIN execute "$service" "$@"
        ;;

    rem|remove|rm)
        if [[ -z "$repo_name" ]]; then
            message 41 "!" "Repository name is required for remove command"
            exit 1
        fi
        
        confirm "Are you sure, remove the $type '$repo_name'?" \
            set -e; \
            _git submodule deinit -f -- $target_dir/$repo_name; \
            rm -rf .git/modules/$target_dir/$repo_name; \
            _git rm -f $target_dir/$REPO_NAME;
        ;;

    upd|update)
        message "Updating all submodules in $target_dir/ .."
        _git submodule update --remote --merge
        ;;

    lin|link)
        if [[ "$type" != "package" ]]; then
            message 41 "!" "Link command is only available for packages"
            exit 1
        fi
        
        message 45 "PACKAGES:" "\n$(ls $target_dir 2>/dev/null || echo 'No packages found')"
        read -p "$(message 45 "?" "Select a package to link:")" PACKAGE
        _npm link ./$target_dir/$PACKAGE
        ;;

    lis|list|ls)
        if [[ -d "$target_dir" ]]; then
            message "45" "${type^^}S in $target_dir:" "\n$(ls $target_dir 2>/dev/null || echo 'No items found')"
        else
            message 43 "ℹ︎" "Directory $target_dir does not exist"
        fi
        ;;

    *)
        if [[ -z "$command" ]]; then
            show_help
        else
            message 41 "!" "Unknown command: $command"
            show_help
        fi
        exit 1
        ;;
esac
