#!/bin/bash

# Load environment variables
# if [ -f /kit/cli ]; then
#   set -a; eval "$(D envs)"; set +a
# fi

# Aliases
alias kit='/kit/cli'
alias vise='/vise/cli'

# Execute the command passed to the container
exec "$@"