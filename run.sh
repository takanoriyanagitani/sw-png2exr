#!/bin/sh

input=~/Downloads/PNG_transparency_demonstration_1.png
output=./out.exr

export ENV_I_PNG_FILENAME="${input}"
export ENV_O_EXR_FILENAME="${output}"

./PngToExr

ls -lSh "${input}" "${output}"

file "${input}"
file "${output}"
