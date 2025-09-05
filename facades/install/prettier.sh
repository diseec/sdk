#!/bin/bash

sdk_fac_set_prettier() {
    cli_stub sdk run \
        _npm install --save-dev --save-exact prettier; \
        _node --eval "fs.writeFileSync('.prettierrc','{}\n')";

    logit -o "Prettier installed and configured"
}
