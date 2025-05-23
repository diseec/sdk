#!/bin/bash

case $1 in
  ssh)
    shift
    chmod 400 ./secrets/key.pem
    ssh -i ./secrets/key.pem \
      -o ServerAliveInterval=60 \
      -o ServerAliveCountMax=3 \
      ubuntu@35.175.43.207 "$@"
  ;;

  update)
    shift
    # for now i dont wish to push all images to dockerhub (public)!
    # ./cli build --push
    ./cli build uix --push
    git add -A && git commit -m "Deploy!" && git push
    bash $0 cli update
  ;;

  cli)
    shift
    bash $0 ssh "/manager/cli $@"
  ;;
  
  --help|-h|*)
    echo "Usage: bash $0 [ssh|update|build|push|deploy]"
    exit 0
  ;;

esac