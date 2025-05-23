#!/bin/bash

# Load the helpers
source $(dirname "$0")/../../helpers.sh

# Get the command
case $1 in
  main-image)
    shift
    # message "Building main-image dependencies..."
    # bash $0 api-php-image
    # # build main only if api-php-image was built successfully
    # if [ $? -eq 0 ]; then
      # message "Building main-image..."
      run_command_in "." "docker build -t main-image ." "$@"
    # fi
    ;;
  api-php-image)
    shift
    message "Building api-php-image..."
    run_command_in "api" "docker build -t api-php-image -f Dockerfile.php ." "$@"
    ;;
  --help|-h)
    color_output 33 "Available Images:"
    color_output 0 "    \e[32mmain-image\e[0m               Main image for the app (under /Dockerfile)"
    color_output 0 "    \e[32mapi-php-image\e[0m            Php image for the api (under /api/Dcockerfile.php)"
    exit 0
    ;;
  *)
    message error "Unknown command: $1"
    exit 1
    ;;
esac
