#!/bin/bash

rsync -avz ../arch_installer $1@$2:/tmp/ --exclude-from="rsync_exclude.txt" --delete-excluded
