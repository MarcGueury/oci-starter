#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export DB_USER="##DB_USER##"
export DB_PASSWORD="##DB_PASSWORD##"
export DB_SHORT_URL="##DB_SHORT_URL##"
node main.js