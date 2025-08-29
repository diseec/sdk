#!/bin/bash

c=$1; shift; case $c in
    pre|prettier) fac_dev_prettier "$@" ;;
    *)
        echo "Usage: $0 <?>"
    ;;
esac
