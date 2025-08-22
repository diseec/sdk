#!/bin/bash

$KIT_DIR/cli run \
    _npm install --save-dev --save-exact prettier; \
    _node --eval "fs.writeFileSync('.prettierrc','{}\n')";
message 42 "OKEY" "Prettier installed and configured"
