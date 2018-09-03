#!/bin/bash -l

#$ -S /bin/bash

#$ -l mem=8G
#$ -l h_rt=24:0:0
#$ -l gpu=1

#$ -N gpu-gan

#$ -wd /home/ucfnmbz/Scratch/output

if [[ -n "$TMPDIR" ]]; then cd $TMPDIR; fi

module unload compilers mpi
module load compilers/gnu/4.9.2

module load python3

module load cuda/9.0.176-patch4/gnu-4.9.2
module load cudnn/7.1.4/cuda-9.0
module load tensorflow/1.8.0/gpu

echo "Running command $1 \"$2\""

$1 "$2"
