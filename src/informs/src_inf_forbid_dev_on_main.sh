#!/bin/bash

src_inf_forbid_dev_on_main() {
    if [ "$CURRENT_BRANCH" = "main" ]; then
        logit -w "On the 'main' branch, consider switching to a subbranch"
    fi
}