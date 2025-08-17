#!/bin/sh

install_cli_globally() {
    npm install -g "$(grep '"name"' $KIT_DIR/package.json | head -n1 | sed 's/.*: *"\([^"]*\)".*/\1/')@latest"
    message 42 "OKEY" "CLI installed globally"
}

install_prettier() {
    $KIT_DIR/cli run \
        npm install --save-dev --save-exact prettier; \
        node --eval "fs.writeFileSync('.prettierrc','{}\n')";
    message 42 "OKEY" "Prettier installed and configured"
}