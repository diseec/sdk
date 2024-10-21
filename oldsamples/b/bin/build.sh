#!/bin/bash
source "$(dirname "$0")/helpers.sh"
load_env

build_image() {
  local push=false
  local service=$1
  shift

  for arg in "$@"; do
    case "$arg" in
      --push)
        push=true
        ;;
    esac
  done

  # Build base image 
  # docker build \
  #   -t $APP_NAME-$service \
  #   $(get_root)/$service

  # Build Production image
  docker build \
    -t $APP_NAME-$service:pro \
    -f ./$service/Dockerfile.pro \
    ./$service

  # Push to Docker Hub
  $push && docker tag $APP_NAME-$service:pro $DOCKER_USERNAME/$APP_NAME-$service:pro
  $push && docker push $DOCKER_USERNAME/$APP_NAME-$service:pro
}

if [ $# -eq 0 ]; then
  build_image uix
  build_image api
  build_image pre
else
  case "$1" in
    uix|api|pre)
      build_image "$@"
      ;;
    *)
      echo "Invalid argument: $1"
      exit 1
      ;;
  esac
fi