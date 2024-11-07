# docker-klipper-simulavr

[![Project Maintenance](https://img.shields.io/maintenance/yes/2024.svg)](https://github.com/pedrolamas/docker-klipper-simulavr 'GitHub Repository')
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
  /klipper
  /klippy-env
  /mjpg-streamer
  /moonraker
  /moonraker-env
  /printer_data
    /config
      /moonraker.conf
      /printer.cfg
    /database
    /gcodes
    /logs
      /klippy.log
      /moonraker.log
      /supervisord.log
    /moonraker.asvc
  /pysimulavr
```

Any of these files can be overrided by mapping the folder or the specific file.

For example, here is how to override the default `printer.cfg`:

```sh
docker run -d \
  --name klipper-simulavr \
  --net=host \
  -v my-printer.cfg:/printer/printer_data/config/printer.cfg \
  ei99070/docker-klipper-simulavr
```

## Klippy Extras

Some Klipper extra modules are included as part of this image, specifically:

- `virtual_pins` - https://github.com/pedrolamas/klipper-virtual-pins
- `gcode_shell_command` - https://github.com/th33xitus/kiauh

## Convenience scripts

The image includes the following convenience scripts:

- `enable-timelapse` - installs the Moonraker Timelapse dependencies, updates the configuration files, and restart Klipper and Moonraker
- `restore-klipper-repo` - restores the Klipper git repository to the same point where the docker image was created
- `restore-moonraker-repo` - restores the Moonraker git repository to the same point where the docker image was created

Once the Docker container has started, these can be easily run:

```sh
docker exec -it klipper-simulavr enable-timelapse
```

## Available tags

- `latest`: points to Klipper and Moonraker "master" branches
- `klipper-sha-<hash>`: points to the Klipper GitHub commit hash
- `moonraker-sha-<hash>`: points to the Moonraker GitHub commit hash

## FAQ

### I keep getting "MCU 'mcu' shutdown: Timer too close"

Start the container with `SIMULAVR_PACING_RATE` environment variable set to something like `0.2`, like this:

```sh
docker run -d \
  --name klipper-simulavr \
  --net=host \
  -e SIMULAVR_PACING_RATE=0.2
  ei99070/docker-klipper-simulavr
```

## Support my work

A lot of time and effort goes into the development of this and other open-source projects.

If you find this project valuable, please consider supporting my work by making a donation.

[![Donate on Paypal](https://img.shields.io/badge/donate-paypal-blue.svg)](https://paypal.me/pedrolamas 'Donate on Paypal')
[![Buy me a coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-kofi-blue.svg)](https://ko-fi.com/pedrolamas 'Buy me a coffee')
[![Support me on Patreon](https://img.shields.io/badge/join-patreon-blue.svg)](https://www.patreon.com/pedrolamas 'Support me on Patreon')
[![Sponsor me on GitHub](https://img.shields.io/github/sponsors/pedrolamas.svg?label=github%20sponsors)](https://github.com/sponsors/pedrolamas 'Sponsor me on GitHub')

Thank you for your generosity and support! 🙏

## License

MIT
