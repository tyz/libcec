# syntax=docker/dockerfile:1.7-labs

FROM python:3.10-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "deb [arch=arm64] http://ftp.nl.debian.org/debian bookworm-backports main" > /etc/apt/sources.list.d/backports.list

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/debconf \
    apt-get update && \
    apt-get install -y --no-install-recommends swig && \
    apt-get install -y --no-install-recommends -t bookworm-backports cmake

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

# FIX/WORKAROUND: setup.py expects it, but it doesn't exist
RUN [ -f "README.rst" ] || echo > README.rst

RUN pip wheel . --wheel-dir=/dist

#########

FROM python:3.10-slim-bookworm

COPY --from=builder /dist /dist

RUN pip install --no-index --find-links=/dist pyCEC && \
    rm -rf /dist

COPY --from=builder /usr/local/bin/*-6.0.2 /usr/local/bin
COPY --from=builder /usr/local/lib/libcec.so.6.0.2 /usr/local/lib/libcec.so.6.0.2
COPY --from=builder /usr/local/lib/python3.10/dist-packages/*cec* /usr/local/lib/python3.10/site-packages

RUN ldconfig

CMD ["python", "-m", "pycec"]
