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
    apt-get install -y --no-install-recommends libxrandr-dev swig sudo && \
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

#RUN --mount=type=cache,target=/root/.cache,sharing=locked \
RUN    pip wheel . --wheel-dir=/dist

#########

FROM python:3.10-slim-bookworm

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/debconf \
    apt-get update && \
    apt-get install -y --no-install-recommends libxrandr-dev

COPY --from=builder /dist /dist

RUN pip install --no-index --find-links=/dist pyCEC && \
    rm -rf /dist

COPY --from=builder /usr/local/bin/cec-client-6.0.2 /usr/local/bin/cec-client
COPY --from=builder /usr/local/bin/cecc-client-6.0.2 /usr/local/bin/cecc-client

COPY --from=builder /usr/local/lib/pkgconfig/libcec.pc /usr/local/lib/pkgconfig/libcec.pc
COPY --from=builder /usr/local/lib/libcec.so.6.0.2 /usr/local/lib/libcec.so.6.0.2

COPY --from=builder /usr/local/lib/python3.10/dist-packages/_pycec.so /usr/local/lib/python3.10/site-packages/_pycec.so
COPY --from=builder /usr/local/lib/python3.10/dist-packages/cec.py /usr/local/lib/python3.10/site-packages/cec.py

RUN ldconfig

CMD ["python", "-m", "pycec"]
