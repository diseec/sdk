#!/bin/bash

# Load environment variables
# if [ -f /kit/cli ]; then
#   set -a; eval "$(D envs)"; set +a
# fi

# Execute the command passed to the container
exec "$@"