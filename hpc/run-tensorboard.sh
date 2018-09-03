#!/bin/bash -l

source ~/Scratch/load-tf-cpu.sh

python3 -m tensorboard.main --port=9999 --logdir="$1"
