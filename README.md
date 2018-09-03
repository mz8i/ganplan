# ganplan
Using deep learning generative models for analysis of urban morphology - code for MSc dissertation in Smart Cities and Urban Analytics at the Centre for Advanced Spatial Analysis, University College London

The title of this repository is a bit out of sync with its contents, because initially I intended the work to be about using generative adversarial networks for planning support. But eventually I used a modification of variational auto-encoder for analysing city structure. The planning support bit might still get added at some point!


## Outline of contents

The repository contains several directories related to different parts of the project:

* `tileserver` - contains the configuration files and styles for a `tileserver-gl` setup
* `tileclient` - contains simple scripts for downloading large sets of tiles from the local tile server
* `python` - contains python code, which was used for processing the map tiles, using the trained models, and performing the analysis of results
* `hpc` - contains job submission scripts which were used on UCL servers operating with the Sun Grid Engine batch job system
* `R` - contains R code, which was used for spatial operations like extracting the urban area boundaries, and for visualising the results of the analysis

## Getting started

More information about setting up and running the project will appear here soon. For now, you can browse the python and R code that I used for creating the dataset, running the models on the UCL high performance computing nodes, perform an analysis of the results, and visualise the results.