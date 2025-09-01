#!/bin/bash

src_inf_check_internet_connection() {
    X
    cli_main internet test "d"
    # if ! cli_main internet is-online; then
    #     if ! cli_main internet test; then
    #         confirm "Found connection issues, diagnose? ~10 secs" cli_main internet diagnose
    #     fi
    # fi
}