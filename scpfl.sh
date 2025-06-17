#!/bin/bash
# copy files from multiple servers to local directory and add suffix to this file name by server from
# using scp and asking for password in prompt
# list of servers and source path from file ~/Sourceservers.txt

scp $1:/$pathtofilefromprompt ~/$copiedfile-$1
