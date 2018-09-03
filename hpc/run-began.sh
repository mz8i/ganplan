#!/bin/bash

python3 /home/$USER/Scratch/BEGAN-tensorflow/main.py --data_dir="/home/$USER/Scratch/data" --dataset="OSM_RASTER_FRANCE" --input_scale_size=128 --log_dir="/home/$USER/Scratch/output/began" $1
