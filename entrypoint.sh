#!/bin/bash

# Load environment variables
# if [ -f /sdk/cli ]; then
#   set -a; eval "$(D envs)"; set +a
# fi

# Aliases
alias sdk='/sdk/cli'

# Execute the command passed to the container
exec "$@"