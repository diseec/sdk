#!/bin/bash

$KIT_DIR/cli run \
    npm install --save-dev --save-exact prettier; \
    node --eval "fs.writeFileSync('.prettierrc','{}\n')";
message 42 "OKEY" "Prettier installed and configured"
