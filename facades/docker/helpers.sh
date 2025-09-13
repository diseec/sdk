#!/bin/bash

sdk_doc_init_compose_files() {
    if [ -f "$D_CTX_DIR/docker-compose.yaml.example" ] && [ ! -f "$D_CTX_DIR/docker-compose.yaml" ]; then
        cp "$D_CTX_DIR/docker-compose.yaml.example" "$D_CTX_DIR/docker-compose.yaml"
        if [ $? -ne 0 ]; then
            rep_failures+=("Failed to copy docker-compose.yaml.example to docker-compose.yaml")
            rep_exit_code=1
        fi
    fi
    if [ -f "$D_CTX_DIR/docker-compose.override.yaml.example" ] && [ ! -f "$D_CTX_DIR/docker-compose.override.yaml" ]; then
        cp "$D_CTX_DIR/docker-compose.override.yaml.example" "$D_CTX_DIR/docker-compose.override.yaml"
        if [ $? -ne 0 ]; then
            rep_failures+=("Failed to copy docker-compose.override.yaml.example to docker-compose.override.yaml")
            rep_exit_code=1
        fi
    fi
}
