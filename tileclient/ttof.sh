#!/bin/bash

cat | tr -d '[],' | while read col row zoom
do
	echo "${zoom}_${col}_${row}.png"
done
