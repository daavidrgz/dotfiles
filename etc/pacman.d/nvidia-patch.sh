#!/bin/bash

git clone --depth=1 https://github.com/keylase/nvidia-patch /tmp/nvidia-patch
cd /tmp/nvidia-patch
./patch.sh
./patch-fbc.sh
cd /tmp
rm -rf /tmp/nvidia-patch
