FROM python:3-bookworm

RUN echo "deb [arch=arm64] http://ftp.nl.debian.org/debian bookworm-backports main" > /etc/apt/sources.list.d/backports.list

RUN apt update && \
    apt install -y libxrandr-dev swig sudo && \
    apt install -y -t bookworm-backports cmake

RUN git clone https://github.com/Pulse-Eight/platform.git
WORKDIR /platform/build
RUN cmake .. && \
    make -j4 && \
    make install

COPY . /libcec
WORKDIR /libcec/build
RUN cmake -DHAVE_LINUX_API=1 .. && \
    make -j4 && \
    make install && \
    ldconfig

WORKDIR /pyCEC
RUN git clone https://github.com/konikvranik/pyCEC.git .
RUN pip install setuptools && \
    python setup.py install

WORKDIR /

ENV PYTHONPATH=/libcec/build/src/libcec

CMD ["bash", "-c", "python -m pycec"]

# TODO:
# * cleanup build stuff
