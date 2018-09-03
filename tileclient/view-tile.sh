#!/bin/bash

cat | sed 's:\(.\+\)_\(.\+\)_\(.\+\)\.png:[\2, \3, \1]:' | supermercado union | fiona collect
