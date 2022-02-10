## build

FROM debian as build

RUN apt update -qq \
  && apt install -y --no-install-recommends \
    avr-libc \
    cmake \
    doxygen \
    fakeroot \
    g++ \
    git \
    graphviz \
    help2man \
    iverilog \
    make \
    nano-tiny \
    python3 \
    python3-dev \
    python3-pip \
    rst2pdf \
    swig \
    texinfo \
    time \
    tk-dev \
    valgrind \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone git://git.savannah.nongnu.org/simulavr.git \
  && cd simulavr \
  && make cfgclean python debian

RUN git clone --depth 1 https://github.com/klipper3d/klipper

COPY klipper/simulavr.config ./klipper/.config

RUN cd klipper \
  && make PYTHON=python3 \
  && mv out/klipper.elf simulavr.elf \
  && rm -rf .git out

RUN git clone --depth 1 https://github.com/Arksine/moonraker \
  && cd moonraker \
  && rm -rf .git

WORKDIR /output

COPY klipper_config ./klipper_config

RUN mv /build/simulavr/build/debian/python3-simulavr*.deb . \
  && mv /build/klipper . \
  && mv /build/moonraker . \
  && cp klipper/config/generic-simulavr.cfg klipper_config/


## final

FROM debian as final

WORKDIR /home/printer

COPY --from=build /output .

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
    gcc \
    iproute2 \
    libcurl4-openssl-dev \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    packagekit \
    python3-dev \
    python3-libgpiod \
    python3-virtualenv \
    sudo \
    supervisor \
    zlib1g-dev \
    ./python3-simulavr*.deb \
  && virtualenv -p python3 klippy-env \
  && ./klippy-env/bin/pip install -r klipper/scripts/klippy-requirements.txt \
  && virtualenv -p python3 moonraker-env \
  && ./moonraker-env/bin/pip install -r moonraker/scripts/moonraker-requirements.txt \
  && apt autoremove -y \
  && apt clean -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && groupadd --force -g 1000 printer \
  && useradd -rm -d /home/printer -g 1000 -u 1000 printer \
  && usermod -aG dialout,tty,sudo printer \
  && echo 'printer ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/printer \
  && chown -hR printer:printer .

COPY ./supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./supervisord/start.sh /bin/start

RUN chmod +x /bin/start

ENTRYPOINT ["/bin/start"]
