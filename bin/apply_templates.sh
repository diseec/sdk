#!/bin/bash

set -e

# Directory containing templates
TEMPLATES_DIR="templates"
CACHE_DIR=".cache"

# Function to list available templates
list_templates() {
  echo "Available templates:"
  ls "$TEMPLATES_DIR"
}

# Function to prompt user to select a template
select_template() {
  read -p "Enter the name of the template you want to use: " TEMPLATE_NAME
  TEMPLATE_DIR="$TEMPLATES_DIR/$TEMPLATE_NAME"
  if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template not found!"
    exit 1
  fi
}

# Function to prompt user for initial inputs
prompt_inputs() {
  read -p "Enter the project id: " PROJECT_ID
  read -p "Enter the project name: " PROJECT_NAME
}

# Function to replace placeholders in files
replace_placeholders() {
  local file=$1
  sed -i "s/placeholderforprojectid/$PROJECT_ID/g" "$file"
  sed -i "s/placeholderforprojectname/$PROJECT_NAME/g" "$file"
}

# Function to process template files
process_template() {
  # Create cache directory
  mkdir -p "$CACHE_DIR"
  shopt -s dotglob

  # Copy template files to cache directory
  cp -r "$TEMPLATE_DIR"/* "$CACHE_DIR"

  # Replace placeholders in cached files
  find "$CACHE_DIR" -type f | while read -r file; do
    replace_placeholders "$file"
  done

  # Move processed files to the mounted project directory
  cp -r "$CACHE_DIR"/* "$MOUNTED_PROJECT_DIR"

  # Clean up cache directory
  rm -rf "$CACHE_DIR"
}

# Main script execution
MOUNTED_PROJECT_DIR="/app"

list_templates
select_template
prompt_inputs
process_template

echo "Template applied successfully!"