## build

FROM debian as build

ARG KLIPPER_SHA
ARG MOONRAKER_SHA

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends --no-install-suggests \
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
    python3 \
    python3-dev \
    python3-virtualenv \
    rst2pdf \
    swig \
    texinfo \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone git://git.savannah.nongnu.org/simulavr.git \
  && ( \
    cd simulavr \
    && make cfgclean python debian \
  )

RUN git clone --depth 1 https://github.com/klipper3d/klipper

COPY klipper/simulavr.config ./klipper/.config

RUN ( \
    cd klipper \
    && ( [ -n "$KLIPPER_SHA" ] && git reset --hard $KLIPPER_SHA || true ) \
    && make PYTHON=python3 \
    && mv out/klipper.elf simulavr.elf \
    && rm -rf .git out \
  ) \
  && virtualenv -p python3 klippy-env \
  && ./klippy-env/bin/pip install -r klipper/scripts/klippy-requirements.txt \
  && ./klippy-env/bin/python -m compileall klipper/klippy \
  && ./klippy-env/bin/python klipper/klippy/chelper/__init__.py

RUN git clone --depth 1 https://github.com/Arksine/moonraker \
  && ( \
    cd moonraker \
    && ( [ -n "$MOONRAKER_SHA" ] && git reset --hard $MOONRAKER_SHA || true ) \
    && rm -rf .git \
  ) \
  && virtualenv -p python3 moonraker-env \
  && ./moonraker-env/bin/pip install -r moonraker/scripts/moonraker-requirements.txt

RUN git clone --depth 1 https://github.com/jacksonliam/mjpg-streamer \
  && ( \
    cd mjpg-streamer \
    && ( \
      cd mjpg-streamer-experimental \
      && mkdir _build \
      && ( \
        cd _build \
        && cmake -DPLUGIN_INPUT_HTTP=OFF -DPLUGIN_INPUT_UVC=OFF -DPLUGIN_OUTPUT_FILE=OFF -DPLUGIN_OUTPUT_RTSP=OFF -DPLUGIN_OUTPUT_UDP=OFF .. \
      ) \
      && make \
      && rm -rf _build \
    ) \
  )

RUN git clone --depth 1 https://github.com/th33xitus/kiauh

RUN git clone --depth 1 https://github.com/mainsail-crew/moonraker-timelapse

COPY mjpg_streamer_images ./mjpg-streamer/mjpg-streamer-experimental/images

WORKDIR /output

COPY klipper_config ./klipper_config

RUN mv /build/simulavr/build/debian/python3-simulavr*.deb . \
  && mv /build/klipper . \
  && mv /build/klippy-env . \
  && mv /build/moonraker . \
  && mv /build/moonraker-env . \
  && mv /build/mjpg-streamer/mjpg-streamer-experimental ./mjpg-streamer \
  && mv /build/kiauh/resources/gcode_shell_command.py ./klipper/klippy/extras/gcode_shell_command.py \
  && mv /build/kiauh/resources/shell_command.cfg ./klipper_config/shell_command.cfg \
  && mv /build/moonraker-timelapse/component/timelapse.py ./moonraker/moonraker/components/timelapse.py \
  && mv /build/moonraker-timelapse/klipper_macro/timelapse.cfg ./klipper_config/timelapse.cfg

## final

FROM debian:bullseye-slim as final

WORKDIR /printer

COPY --from=build /output .

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    iproute2 \
    libcurl4-openssl-dev \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    sudo \
    supervisor \
    zlib1g-dev \
    ./python3-simulavr*.deb \
  && rm -f ./python3-simulavr*.deb \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && groupadd --force -g 1000 printer \
  && useradd -rm -d /printer -g 1000 -u 1000 printer \
  && echo 'printer ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/printer \
  && mkdir gcode_files klipper_logs \
  && chown -hR printer:printer .

COPY ./rootfs /

RUN chmod +x /bin/start /bin/systemctl

USER printer

ENTRYPOINT ["/bin/start"]
