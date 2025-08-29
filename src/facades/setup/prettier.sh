#!/bin/bash

fac_set_prettier() {
    cli_main kit run \
        _npm install --save-dev --save-exact prettier; \
        _node --eval "fs.writeFileSync('.prettierrc','{}\n')";

    message 42 ✔ "Prettier installed and configured"
}
