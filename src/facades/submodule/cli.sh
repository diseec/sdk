#!/bin/bash

# Unified submodule management for packages and services
# Default behavior follows git submodule conventions

# Parse options
TYPE=""
TARGET_DIR=""
REPO_NAME=""
COMMAND=""

# Function to show help
show_help() {
    message 33 "SUBMODULE" "Unified submodule management for packages and services"
    echo ""
    echo "Usage: cli submodule [OPTIONS] <command> [arguments]"
    echo ""
    echo "Options:"
    echo "  --type <package|service>   - Specify submodule type (default: auto-detect from target dir)"
    echo "  --dir <directory>          - Target directory (default: packages/ or services/ based on type)"
    echo ""
    echo "Commands:"
    echo "  add <name>                 - Add submodule from repository"
    echo "  rem|remove|rm <name>       - Remove submodule"
    echo "  upd|update                 - Update all submodules"
    echo "  run                        - Run command in service container (services only)"
    echo "  lin|link                   - Link local package for development (packages only)"
    echo ""
    echo "Examples:"
    echo "  cli submodule add my-package                    # Adds to packages/"
    echo "  cli submodule --type service add my-service     # Adds to services/"
    echo "  cli submodule --dir custom/path add my-repo     # Custom directory"
    echo "  cli submodule remove my-package"
    echo "  cli submodule update"
    echo ""
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            else
                REPO_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Auto-detect type and directory if not specified
if [[ -z "$TYPE" && -z "$TARGET_DIR" ]]; then
    # Default to submodules
    TYPE="submodule"
    TARGET_DIR="submodules"
elif [[ -n "$TYPE" && -z "$TARGET_DIR" ]]; then
    case $TYPE in
        submodule)
            TARGET_DIR="submodules"
            ;;
        package)
            TARGET_DIR="packages"
            ;;
        service)
            TARGET_DIR="services"
            ;;
        *)
            message 31 "ERROR" "Unknown type: $TYPE. Use 'package' or 'service'"
            exit 1
            ;;
    esac
elif [[ -z "$TYPE" && -n "$TARGET_DIR" ]]; then
    # Auto-detect type from directory
    case $TARGET_DIR in
        submodules|submodules/*)
            TYPE="submodule"
            ;;
        packages|packages/*)
            TYPE="package"
            ;;
        services|services/*)
            TYPE="service"
            ;;
        *)
            TYPE="custom"
            ;;
    esac
fi

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

case $COMMAND in
    add)
        if [[ -z "$REPO_NAME" ]]; then
            message 31 "ERROR" "Repository name is required for add command"
            exit 1
        fi
        
        message "Adding $TYPE '$REPO_NAME' to $TARGET_DIR/ .."
        set -e
        _git submodule add https://$REPO_HUB_URL/$REPO_NAME.git $TARGET_DIR/$REPO_NAME
        _git submodule update --init --recursive
        ;;

    run)
        if [[ "$TYPE" != "service" ]]; then
            message 31 "ERROR" "Run command is only available for services"
            exit 1
        fi
        
        services=$(docker compose config --services)
        message "45" "SERVICES:" "\n$services"
        read -p "$(message 45 "?" "Specify a service to run:")" service
        $CLI_MAIN execute "$service" "$@"
        ;;

    rem|remove|rm)
        if [[ -z "$REPO_NAME" ]]; then
            message 31 "ERROR" "Repository name is required for remove command"
            exit 1
        fi
        
        confirm "Are you sure, remove the $TYPE '$REPO_NAME'?" \
            set -e; \
            _git submodule deinit -f -- $TARGET_DIR/$REPO_NAME; \
            rm -rf .git/modules/$TARGET_DIR/$REPO_NAME; \
            _git rm -f $TARGET_DIR/$REPO_NAME;
        ;;

    upd|update)
        message "Updating all submodules in $TARGET_DIR/ .."
        _git submodule update --remote --merge
        ;;

    lin|link)
        if [[ "$TYPE" != "package" ]]; then
            message 31 "ERROR" "Link command is only available for packages"
            exit 1
        fi
        
        message "45" "PACKAGES:" "\n$(ls $TARGET_DIR 2>/dev/null || echo 'No packages found')"
        read -p "$(message 45 "?" "Select a package to link:")" PACKAGE
        _npm link ./$TARGET_DIR/$PACKAGE
        ;;

    lis|list|ls)
        if [[ -d "$TARGET_DIR" ]]; then
            message "45" "${TYPE^^}S in $TARGET_DIR:" "\n$(ls $TARGET_DIR 2>/dev/null || echo 'No items found')"
        else
            message 33 "INFO" "Directory $TARGET_DIR does not exist"
        fi
        ;;

    *)
        if [[ -z "$COMMAND" ]]; then
            show_help
        else
            message 31 "ERROR" "Unknown command: $COMMAND"
            show_help
        fi
        exit 1
        ;;
esac
