#!/bin/bash

sdk_doc_init_compose_files() {
    local ctx_dir="${1:-$D_CTX_DIR}"

    if [ -f "$ctx_dir/docker-compose.yaml.example" ] && [ ! -f "$ctx_dir/docker-compose.yaml" ]; then
        
        stdout -l "Copying docker-compose.yaml example to $ctx_dir"
        
        cp "$ctx_dir/docker-compose.yaml.example" "$ctx_dir/docker-compose.yaml"
        if [ $? -ne 0 ]; then
            stdout -e "Failed to copy docker-compose.yaml.example to docker-compose.yaml"
            exit_status=$?
        fi
        fix_permissions "$ctx_dir/docker-compose.yaml"
    fi

    if [ -f "$ctx_dir/docker-compose.override.yaml.example" ] && [ ! -f "$ctx_dir/docker-compose.override.yaml" ]; then
        
        stdout -l "Copying docker-compose.override.yaml example to $ctx_dir"
        
        cp "$ctx_dir/docker-compose.override.yaml.example" "$ctx_dir/docker-compose.override.yaml"
        if [ $? -ne 0 ]; then
            stdout -e "Failed to copy docker-compose.override.yaml.example to docker-compose.override.yaml"
            exit_status=$?
        fi
        fix_permissions "$ctx_dir/docker-compose.override.yaml"
    fi

    return $exit_status
}