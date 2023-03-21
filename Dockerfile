# syntax = docker/dockerfile:1.4

ARG PYTHON_VERSION=3

## build

FROM debian as build

ARG KLIPPER_SHA
ARG MOONRAKER_SHA
ARG PYTHON_VERSION

RUN <<eot
  apt-get update -qq
  apt-get install -y --no-install-recommends --no-install-suggests \
    avr-libc \
    cmake \
    fakeroot \
    g++ \
    git \
    help2man \
    libcurl4-openssl-dev \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    make \
    python \
    python-dev \
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

RUN git clone https://github.com/klipper3d/klipper

COPY klipper ./klipper/

RUN <<eot
  (
    cd klipper
    [ -n "$KLIPPER_SHA" ] && git reset --hard $KLIPPER_SHA || true
    make PYTHON=python${PYTHON_VERSION}
    mv out/klipper.elf simulavr.elf
    rm -rf .git out
  )
  virtualenv -p python${PYTHON_VERSION} klippy-env
  ./klippy-env/bin/pip install -r klipper/scripts/klippy-requirements.txt
  ./klippy-env/bin/python -m compileall klipper/klippy
  ./klippy-env/bin/python klipper/klippy/chelper/__init__.py
eot

RUN <<eot
  git clone https://github.com/Arksine/moonraker
  (
    cd moonraker
    [ -n "$MOONRAKER_SHA" ] && git reset --hard $MOONRAKER_SHA || true
    rm -rf .git
  )
  virtualenv -p python3 moonraker-env
  ./moonraker-env/bin/pip install -r moonraker/scripts/moonraker-requirements.txt
eot

RUN <<eot
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
eot

## final

FROM debian:bullseye-slim as final

ARG PYTHON_VERSION

WORKDIR /printer

COPY --from=build /output .

RUN <<eot
  apt-get update -qq
  apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    iproute2 \
    libcurl4-openssl-dev \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    python${PYTHON_VERSION} \
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

RUN chmod +x /bin/start /bin/systemctl /bin/enable-timelapse

USER printer

ENTRYPOINT ["/bin/start"]
