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

This will start Klipper with a simulates Atmel ATmega micro-controller, and Moonraker on port 7125.

These default configuration files used can be found on the [/klipper_config](/klipper_config) folder.

To override any of these, just map the alternative file:

```sh
docker run -d \
  --name klipper-simulavr \
  --net=host \
  -v my-printer.cfg:/printer/klipper_config/printer.cfg \
  -v my-moonraker.conf:/printer/klipper_config/moonraker.conf \
  ei99070/docker-klipper-simulavr
```

## License

MIT
