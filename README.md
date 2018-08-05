360nosc0pe Vivado Docker environment
====================================

This repo contains a Dockerfile and a bunch of helper scripts to run Vivado inside a docker container.

For more information about the whole project check out the README in the [yocto build environment](https://github.com/360nosc0pe/yocto).

Building
--------

### Building the container

Download Vivado in the right version and put it into the `files` subdirectory. Also put your `Xilinx.lic` license file into the same directory.

If you want to use a Webpack license, you need to modify the `files/install_config_2018.2.txt` file and change the Edition to an appropriate value (TODO: Find out what value)

To built the container just run:

    ./build.sh

If you want to run the container, run:

    ./run.sh

The container will mount the directory one level above the `run.sh` script into `/project`.
