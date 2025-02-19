FROM python:3-bookworm

RUN echo deb [arch=arm64] http://ftp.nl.debian.org/debian bookworm-backports main > /etc/apt/sources.list.d/backports.list && \
    echo deb [arch=arm64 signed-by=/etc/apt/keyrings/rpi.asc] http://archive.raspberrypi.com/debian bookworm main > /etc/apt/sources.list.d/rpi.list && \
    curl -so /etc/apt/keyrings/rpi.asc https://archive.raspberrypi.com/debian/raspberrypi.gpg.key && \
    apt update
RUN apt install -y libraspberrypi-dev libudev-dev libxrandr-dev swig sudo && \
    apt install -y -t bookworm-backports cmake

RUN git clone https://github.com/Pulse-Eight/platform.git
WORKDIR /platform/build
RUN cmake .. && \
    make -j4 && \
    make install

COPY . /libcec
WORKDIR /libcec/build
RUN cmake -DRPI_INCLUDE_DIR=/usr/include -DRPI_LIB_DIR=/usr/lib/aarch64-linux-gnu .. && \
    make -j4 && \
    make install && \
    ldconfig


WORKDIR /pyCEC
RUN git clone https://github.com/konikvranik/pyCEC.git .
RUN pip install setuptools && \
    python setup.py install

WORKDIR /

CMD ["bash", "-c", "PYTHONPATH=/libcec/build/src/libcec LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libbcm_host.so python -m pycec"]

# TODO:
# * cleanup build stuff
