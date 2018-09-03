#!/bin/bash -l

#$ -S /bin/bash

#$ -l mem=8G
#$ -l h_rt=24:0:0
#$ -l gpu=1

#$ -N gpu-gan

#$ -wd /home/ucfnmbz/Scratch/output/began

if [[ -n "$TMPDIR" ]]; then cd $TMPDIR; fi

module unload compilers
module unload mpi
module unload tensorflow
module unload cuda
module unload cudnn

module load compilers/gnu/4.9.2

module load python3

module load tensorflow/1.8.0/cpu
