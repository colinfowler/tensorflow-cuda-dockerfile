ARG UBUNTU_VERSION=18.04

ARG ARCH=
ARG CUDA=10.1
FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION} as base
# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.2.24-1

# Needed for string substitution
		software-properties-common \
		unzip

RUN [ ${ARCH} = ppc641e ] || (apt-get update && \
		apt-get install -y --no-install-recommends libvinfer5=5.1.5-1+cuda${CUDA} \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/*)

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ls -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
	&& echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
	&& ldconfig

ARG USE_PYTHON_3_NOT_2=3
ARG _PY_SUFFIX=${USE_PYTHON_3_NOT_2:+3}
ARG PYTHON=python${_PY_SUFFIX}
ARG PIP=pip${_PY_SUFFIX}

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
	python3.7 \
	${PYTHON}-pip

RUN ${PIP} --no-cache-dir install --upgrade \
	pip \
	setuptools

# Some TF tools expect a "python" binary
RUN ls -s $(which ${PYTHON}) /usr/local/bin/python

# Set --build-arg TF_PACKAGE_VERSION=1.11.0rc0 to install a specific version.
# Installs the latest version by default.
ARG TF_PACKAGE=tensorflow-gpu
ARG TF_PACKAGE_VERSION=
ARG KERAS_PACKAGE=keras
RUN ${PIP} install ${TF_PACKAGE}${TF_PACKAGE_VERSION:+==${TF_PACKAGE_VERSION}}
RUN ${PIP} install tensorflow_datasets
RUN ${PIP} install ${KERAS_PACKAGE}${KERAS_PACKAGE_VERSION:+==${KERAS_PACKAGE_VERSION}}

