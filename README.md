# docker-klipper-simulavr

[![Project Maintenance](https://img.shields.io/maintenance/yes/2023.svg)](https://github.com/pedrolamas/docker-klipper-simulavr 'GitHub Repository')
[![License](https://img.shields.io/github/license/pedrolamas/docker-klipper-simulavr.svg)](https://github.com/pedrolamas/docker-klipper-simulavr/blob/master/LICENSE 'License')

[![Release](https://github.com/pedrolamas/docker-klipper-simulavr/workflows/Release/badge.svg)](https://github.com/pedrolamas/docker-klipper-simulavr/actions 'Build Status')

[![Follow pedrolamas on Twitter](https://img.shields.io/twitter/follow/pedrolamas?label=Follow%20@pedrolamas%20on%20Twitter&style=social)](https://twitter.com/pedrolamas)
[![Follow pedrolamas on Mastodon](https://img.shields.io/mastodon/follow/109365776481898704?label=Follow%20@pedrolamas%20on%20Mastodon&domain=https%3A%2F%2Fhachyderm.io&style=social)](https://hachyderm.io/@pedrolamas)

Simple Docker image running [Klipper](https://github.com/Klipper3d/klipper/) with Simulavr, [Moonraker](https://github.com/Arksine/moonraker/), and [mjpg-streamer](https://github.com/jacksonliam/mjpg-streamer).

This repo will run a GitHub action every hour to check for new code on the "master" branches of the Klipper and Moonraker repositories, and creates a new Docker image if there are any modifications.

## Usage

Create and run the new container as you would normally do:

```sh
docker run -d \
  --name klipper-simulavr \
  --net=host \
  ei99070/docker-klipper-simulavr
```

This will start Klipper with a simulated Atmel ATmega micro-controller, Moonraker on port 7125, and mjpg-streamer on port 8080.

If you need to remap the default ports, run the container under the bridge network instead:

```sh
docker run -d \
  --name klipper-simulavr \
  -p 7125:7125 \
  -p 8080:8080 \
  ei99070/docker-klipper-simulavr
```

The default configuration files used can be found on the [klipper_config](/klipper_config) folder.

This is the runtime folder structure:

```txt
/printer
  /.moonraker_database
  /gcode-files
  /klipper
  /klipper_config
    /moonraker.conf
    /printer.cfg
  /klipper_logs
    /klippy.log
    /moonraker.log
    /supervisord.log
  /klippy-env
  /mjpg-streamer
  /moonraker
  /moonraker-env
  /printer_data
    /config -> ../klipper_config
    /database -> ../.moonraker_database
    /gcodes -> ../gcode_files
    /logs -> ../klipper_logs
  /pysimulavr
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

## Klippy Extras

Some Klipper extra modules are included as part of this image, specifically:

- `virtual_pins` - https://github.com/pedrolamas/klipper-virtual-pins
- `gcode_shell_command` - https://github.com/th33xitus/kiauh

## Available tags

For Klipper running on Python3:

- `latest` or `latest-python3`: points to Klipper and Moonraker "master" branches
- `klipper-sha-<hash>` or `klipper-sha-<hash>-python3`: points to the Klipper GitHub commit hash
- `moonraker-sha-<hash>` or `mooranker-sha-<hash>-python3`: points to the Moonraker GitHub commit hash

For Klipper running on Python2:

- `latest-python2`: points to Klipper and Moonraker "master" branches
- `klipper-sha-<hash>-python2`: points to the Klipper GitHub commit hash
- `mooranker-sha-<hash>-python2`: points to the Moonraker GitHub commit hash

## License

MIT
