# syntax = docker/dockerfile:1.6

## build

ARG KLIPPER_REPOSITORY=https://github.com/klipper3d/klipper
ARG MOONRAKER_REPOSITORY=https://github.com/Arksine/moonraker
ARG KLIPPER_SHA
ARG MOONRAKER_SHA

FROM debian:bookworm as build

ARG KLIPPER_REPOSITORY
ARG MOONRAKER_REPOSITORY
ARG KLIPPER_SHA
ARG MOONRAKER_SHA

RUN <<eot
  set -e
  apt-get update -qq
  apt-get install -y --no-install-recommends --no-install-suggests \
    avr-libc \
    cmake \
    fakeroot \
    g++ \
    git \
    help2man \
    libcurl4-openssl-dev \
    libffi-dev \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    make \
    python3 \
    python3-dev \
    python3-virtualenv \
    rst2pdf \
    swig \
    texinfo
  rm -rf /var/lib/apt/lists/*
eot

WORKDIR /build

RUN <<eot
  set -e
  git clone git://git.savannah.nongnu.org/simulavr.git
  (
    cd simulavr
    make cfgclean python build
    (
      cd build/pysimulavr
      mkdir pysimulavr
      strip *.so -o pysimulavr/_pysimulavr.so
      cp pysimulavr.py pysimulavr/
    )
  )
eot

RUN git clone $KLIPPER_REPOSITORY klipper

COPY klipper ./klipper/

RUN <<eot
  set -e
  (
    cd klipper
    [ -n "$KLIPPER_SHA" ] && git reset --hard $KLIPPER_SHA || true
    make
    mv out/klipper.elf simulavr.elf
    rm -rf .git lib out src
  )
  virtualenv klippy-env
  ./klippy-env/bin/pip install -r klipper/scripts/klippy-requirements.txt
  ./klippy-env/bin/python klipper/klippy/chelper/__init__.py
eot

RUN <<eot
  set -e
  git clone $MOONRAKER_REPOSITORY moonraker
  (
    cd moonraker
    [ -n "$MOONRAKER_SHA" ] && git reset --hard $MOONRAKER_SHA || true
    rm -rf .git
  )
  virtualenv moonraker-env
  ./moonraker-env/bin/pip install -r moonraker/scripts/moonraker-requirements.txt
eot

RUN <<eot
  set -e
  git clone --depth 1 https://github.com/jacksonliam/mjpg-streamer
  (
    cd mjpg-streamer
    (
      cd mjpg-streamer-experimental
      mkdir _build
      (
        cd _build
        cmake -DPLUGIN_INPUT_HTTP=OFF -DPLUGIN_INPUT_UVC=OFF -DPLUGIN_OUTPUT_FILE=OFF -DPLUGIN_OUTPUT_RTSP=OFF -DPLUGIN_OUTPUT_UDP=OFF ..
      )
      make
      rm -rf _build
    )
  )
eot

RUN git clone --depth 1 https://github.com/pedrolamas/klipper-virtual-pins

RUN git clone --depth 1 https://github.com/th33xitus/kiauh

RUN git clone --depth 1 https://github.com/mainsail-crew/moonraker-timelapse

COPY mjpg_streamer_images ./mjpg-streamer/mjpg-streamer-experimental/images

WORKDIR /output

COPY klipper_config ./printer_data/config

RUN <<eot
  set -e
  (
    cd printer_data
    mkdir comms
    mkdir database
    mkdir gcodes
    mkdir logs
  )
  mv /build/klipper .
  mv /build/klippy-env .
  mv /build/moonraker .
  mv /build/moonraker-env .
  mv /build/simulavr/build/pysimulavr/pysimulavr .
  mv /build/mjpg-streamer/mjpg-streamer-experimental ./mjpg-streamer
  mv /build/klipper-virtual-pins/virtual_pins.py ./klipper/klippy/extras/virtual_pins.py
  mv /build/kiauh/resources/gcode_shell_command.py ./klipper/klippy/extras/gcode_shell_command.py
  mv /build/kiauh/resources/shell_command.cfg ./printer_data/config/printer/shell_command.cfg
  mv /build/moonraker-timelapse/component/timelapse.py ./moonraker/moonraker/components/timelapse.py
  mv /build/moonraker-timelapse/klipper_macro/timelapse.cfg ./printer_data/config/printer/timelapse.cfg
  ./klippy-env/bin/python -m compileall klipper/klippy
  ./moonraker-env/bin/python -m compileall moonraker/moonraker
  python3 -m compileall pysimulavr
eot

## final

FROM debian:bookworm-slim as final

ARG KLIPPER_REPOSITORY
ARG MOONRAKER_REPOSITORY
ARG KLIPPER_SHA
ARG MOONRAKER_SHA

ENV KLIPPER_REPOSITORY=$KLIPPER_REPOSITORY
ENV MOONRAKER_REPOSITORY=$MOONRAKER_REPOSITORY
ENV KLIPPER_SHA=$KLIPPER_SHA
ENV MOONRAKER_SHA=$MOONRAKER_SHA
ENV SIMULAVR_PACING_RATE=0.0

WORKDIR /printer

COPY --from=build /output .

RUN <<eot
  set -e
  apt-get update -qq
  apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    curl \
    iproute2 \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    sudo \
    supervisor \
    zlib1g-dev
  apt-get autoremove -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
  groupadd --force -g 1000 printer
  useradd -rm -d /printer -g 1000 -u 1000 printer
  echo 'printer ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/printer
  chown -hR printer:printer .
eot

COPY ./rootfs /

USER printer

ENTRYPOINT ["/usr/bin/start"]
