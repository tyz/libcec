FROM python:3

RUN echo deb http://deb.debian.org/debian bookworm-backports main > /etc/apt/sources.list.d/backports.list
RUN apt-get update
RUN apt-get -y install libudev-dev libxrandr-dev swig sudo
RUN apt install -y -t bookworm-backports cmake

WORKDIR /
RUN git clone https://github.com/Pulse-Eight/platform.git
RUN git clone https://github.com/Pulse-Eight/libcec.git
RUN git clone https://github.com/raspberrypi/userland.git

WORKDIR /userland
RUN ./buildme

WORKDIR /platform/build
RUN cmake .. && make && make install

WORKDIR /libcec/build
RUN cmake -DRPI_INCLUDE_DIR=/opt/vc/include -DRPI_LIB_DIR=/opt/vc/lib ..
RUN make -j4
RUN make install
RUN ldconfig

WORKDIR /
