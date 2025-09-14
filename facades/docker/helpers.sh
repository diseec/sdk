#!/bin/bash

sdk_doc_init_compose_files() {
    local ctx_dir="${D_CTX_DIR:-$(pwd)}"

    if [ -f "$ctx_dir/docker-compose.yaml.example" ] && [ ! -f "$ctx_dir/docker-compose.yaml" ]; then
        cp "$ctx_dir/docker-compose.yaml.example" "$ctx_dir/docker-compose.yaml"
        if [ $? -ne 0 ]; then
            rep_failures+=("Failed to copy docker-compose.yaml.example to docker-compose.yaml")
            rep_exit_code=1
        fi
    fi
    if [ -f "$ctx_dir/docker-compose.override.yaml.example" ] && [ ! -f "$ctx_dir/docker-compose.override.yaml" ]; then
        cp "$ctx_dir/docker-compose.override.yaml.example" "$ctx_dir/docker-compose.override.yaml"
        if [ $? -ne 0 ]; then
            rep_failures+=("Failed to copy docker-compose.override.yaml.example to docker-compose.override.yaml")
            rep_exit_code=1
        fi
    fi
}