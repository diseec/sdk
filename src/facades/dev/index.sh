#!/bin/bash

FACADE dev

# _CLI_ interface
c=$1; shift; case $c in
    for|format) check_system_dependencies ;;
    "");;*)
        echo "Usage: $0 <?>"
        ;;
esac
