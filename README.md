# docker-klipper-simulavr

[![Project Maintenance](https://img.shields.io/maintenance/yes/2022.svg)](https://github.com/pedrolamas/docker-klipper-simulavr 'GitHub Repository')
[![License](https://img.shields.io/github/license/pedrolamas/docker-klipper-simulavr.svg)](https://github.com/pedrolamas/docker-klipper-simulavr/blob/master/LICENSE 'License')

[![CI](https://github.com/pedrolamas/docker-klipper-simulavr/workflows/CI/badge.svg)](https://github.com/pedrolamas/docker-klipper-simulavr/actions 'Build Status')

[![Twitter Follow](https://img.shields.io/twitter/follow/pedrolamas?style=social)](https://twitter.com/pedrolamas '@pedrolamas')

Simple Docker image running a Simulavr, Klipper, and Moonraker

## Usage

Create and run the new container as you would normally do:

```sh
docker run -d \
  --name klipper-simulavr \
  --net=host \
  ei99070/docker-klipper-simulavr
```

This will start Klipper with a simulated Atmel ATmega micro-controller, and Moonraker on port 7125.

The default configuration files used can be found on the [klipper_config](/klipper_config) folder.

This is the runtime folder structure:

```txt
/printer
  /gcode-files
  /klipper
  /klipper_config
    /generic-simulavr.cfg
    /moonraker.conf
    /printer.cfg
  /klipper_logs
    /klippy.log
    /moonraker.log
    /supervisord.log
  /klippy-env
  /moonraker
  /moonraker-env
```

Any of these files can be overrided by mapping the folder or the specific file.

For example, here is how to override the default `printer.cfg`:

```sh
docker run -d \
  --name klipper-simulavr \
  --net=host \
  -v my-printer.cfg:/printer/klipper_config/printer.cfg \
  ei99070/docker-klipper-simulavr
```

## License

MIT
