#!/bin/bash

fac_set_prettier() {
    _CLI_ kit run \
        _npm install --save-dev --save-exact prettier; \
        _node --eval "fs.writeFileSync('.prettierrc','{}\n')";

    message 42 "OKEY" "Prettier installed and configured"
}
