#!/usr/bin/env bash

## GETS THE CURRENT MODULE ROOT DIRECTORY
MOD_DUNGON_MASTER_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"

source $MOD_DUNGON_MASTER_ROOT"/conf/conf.sh.dist"

if [ -f $MOD_DUNGON_MASTER_ROOT"/conf/conf.sh" ]; then
    source $MOD_DUNGON_MASTER_ROOT"/conf/conf.sh"
fi
