#!/bin/bash

if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then logit -e "The 'act' command works only on bench! (the kit container)"; exit 1; fi

c=$1; shift; case $c in
    pat|patch) kit_fac_act_patch "$@" ;;
    # templates) bash bin/templates.sh ;;
    hel|help|--help|-h)
        display_help \
            "" "" \
            "$(ansi 97 'Package Visibility Commands')" "" \
            "    pat|patch             " "Force fresh install to mounted directory"
    ;;
    *) if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi ;;
esac
