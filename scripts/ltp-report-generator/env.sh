#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

cd $SCRIPT_DIR

cd ../../

ansible-playbook scripts/ltp-report-generator/copy_file_to_remote.yml

