FROM quay.io/pawsey/mpich-base:3.4.3_ubuntu20.04

MAINTAINER Cormac Reynolds <cormac.reynolds@csiro.au>

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV LD_LIBRARY_PATH=/difx/difx-2.8.1/lib
ENV PATH=${PATH}:/difx/difx-2.8.1/bin
ENV PERL5LIB=/difx/difx-2.8.1/share/perl/5.30.0:/difx/difx-2.8.1/./lib/x86_64-linux-gnu/perl/5.30.0
#ENV TZ=UTC
#ENV TZ=Australia/Perth
ENV TZ=US/Eastern
WORKDIR /difx/

RUN apt-get update

RUN apt-get install -y \
        tzdata \
        autoconf \
        automake \
        libtool \
        pkg-config \
        g++ \
        gcc \
        gfortran \
        git \
        make \
        python3 \
        python3-pip \
        libgsl23 \
        libgsl-dev \
        libexpat1-dev \
        bison \
        doxygen \
        python3-tk \
        vim \
        openssh-client \
        libfftw3-dev \
        build-essential \
        autotools-dev \
        flex \
        subversion

# NB: because we use quay.io/pawsey/mpich-base, these are already handled 
#RUN apt-get install -y \
#        openmpi-bin \
#        flex-old

RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install astropy requests numpy simplejson psutil matplotlib

# obtain IPP and DIFX source from repositories with verification
RUN echo "" > check.sha256sum
RUN wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/c8d09493-ca9b-45b1-b720-12b8719b4136/l_ipp_oneapi_p_2021.11.0.532_offline.sh \
    && echo "42bfaf593184e3293c10e06ccc9e9781427d86a8a88e3d09f6921ffd7de24ee6 *l_ipp_oneapi_p_2021.11.0.532_offline.sh" >> check.sha256sum \
    && chmod +x l_ipp_oneapi_p_2021.11.0.532_offline.sh
RUN wget https://github.com/difx/difx/archive/refs/tags/v2.8.1.tar.gz \
    && echo "7338127efc2322e6e2c73d6948c6319806e7862279aa28e8733298b0fc93ac1e *v2.8.1.tar.gz" >> check.sha256sum
RUN sha256sum -c check.sha256sum

# install IPP
RUN ./l_ipp_oneapi_p_2021.11.0.532_offline.sh -a -s --eula accept

# build DIFX
RUN tar xzf v2.8.1.tar.gz
# NB: need to 'modify' genipppc to handle IPPROOT (believe it or not, I couldn't come up with anything that would satisfy genipppc in v2.8.1)
COPY genipppc difx-2.8.1/genipppc
RUN source ./difx-2.8.1/setup.bash \
    && export IPPROOT=/opt/intel/oneapi/ipp/latest \
    && mkdir /difx/build \
    && cd /difx/build \
    && /difx/difx-2.8.1/install-difx --perl \
    && rm -rf /difx/build

#COPY espresso espresso
#RUN cd /difx/espresso; ./install.py $DIFXROOT
