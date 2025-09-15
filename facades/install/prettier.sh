#!/bin/bash

sdk_fac_ins_prettier() {
    cli_ctx sdk run \
        _npm install --save-dev --save-exact prettier; \
        _node --eval "fs.writeFileSync('.prettierrc','{}\n')";

    stdout -o "Prettier installed and configured"
}
