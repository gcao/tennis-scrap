#!/bin/bash

# Run at 11:30AM
echo "30    11  *   *   *   $(which ruby) $(pwd)/lib/scrap.rb" > /tmp/crontab

# WARN: This will overwrite old crontab 
crontab /tmp/crontab

