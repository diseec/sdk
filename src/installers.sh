#!/bin/sh

install_prettier() {
    docker run --rm \
        -v $(pwd):/project \
        --workdir "/project" \
        $IMAGE_REGISTRY_URL/devops \
            npm install --save-dev --save-exact prettier; \
            node --eval "fs.writeFileSync('.prettierrc','{}\n')";
}