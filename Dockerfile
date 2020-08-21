FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

# Fix "Couldn't register with accessibility bus" error message
ENV NO_AT_BRIDGE=1

ENV DEBIAN_FRONTEND noninteractive

# basic stuff
RUN echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf \
    && apt-get update && apt-get install \
    bash \
    build-essential \
    dbus-x11 \
    fontconfig \
    gettext \
    git \
    language-pack-en-base \
    libgl1-mesa-glx \
    make \
    sudo \
    unzip \
# su-exec
    && git clone https://github.com/ncopa/su-exec.git /tmp/su-exec \
    && cd /tmp/su-exec \
    && make \
    && chmod 770 su-exec \
    && mv ./su-exec /usr/local/sbin/ \
# Cleanup
    && rm -rf /tmp/* /var/lib/apt/lists/* /root/.cache/*

COPY asEnvUser /usr/local/sbin/

# Only for sudoers
RUN chown root /usr/local/sbin/asEnvUser \
    && chmod 700  /usr/local/sbin/asEnvUser

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.0.5

#Install Julia
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    wget \

#Download and install Julia
    && mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \

    && rm -rf /tmp/* /var/lib/apt/lists/* /root/.cache/*

RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

RUN useradd -m jovyan
RUN adduser jovyan sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV HOME=/home/jovyan
WORKDIR $HOME

RUN mkdir /opt/julia && \
    chown jovyan /opt/julia

USER jovyan

ENV DISPLAY=":14"

RUN sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libffi-dev \
    libgtk-3-dev \
    libpython3-dev \
    python3-pip \
    python3-setuptools \
    xvfb \
    xauth \
    libvorbisenc2 \
    libxvidcore4 \

    && sudo pip3 install wheel \
    && sudo pip3 install sklearn \

    && julia -e 'import Pkg; Pkg.update()' \
    && julia -e 'import Pkg; Pkg.add(["Gtk"]); Pkg.add(Pkg.PackageSpec(url="https://github.com/paulmthompson/WhiskerTracking.jl"))' \
    && xvfb-run julia -e 'using WhiskerTracking' \

    && sudo rm -rf /tmp/* /var/lib/apt/lists/* /root/.cache/*

COPY test_gui.jl /home/jovyan/test_gui.jl
USER root

RUN nvcc --version

ENTRYPOINT ["/usr/local/sbin/asEnvUser"]

CMD ["julia", "/home/jovyan/test_gui.jl"]
