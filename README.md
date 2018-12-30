# Docker Base Image for BBQLinux
This repository contains all scripts and files needed to create a Docker base image for the BBQLinux distribution.
## Dependencies
Install the following Arch Linux packages:
* make
* devtools
## Usage
Run `make docker-image` as root to build the base image.
## Purpose
* Provide the BBQLinux experience in a Docker Image
* Provide the most simple but complete image to base every other upon
* `pacman` needs to work out of the box
* All installed packages have to be kept unmodified
