FROM ubuntu:18.04
LABEL description="Base docker image with CUDA 10.1 and cuDNN 7.6 for developing and performing compute in containers on NVIDIA GPU."
LABEL maintainer="Vlad Klim, vladsklim@gmail.com"

# Packages versions
ENV CUDA_VERSION=10.1.243 \ 
    CUDA_PKG_VERSION=10-1=10.1.243-1 \
    NCCL_VERSION=2.4.8 \
    CUDNN_VERSION=7.6.5.32

# BASE
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*


RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub


# RUNTIME AND DEVEL CUDA
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends cuda-cudart-$CUDA_PKG_VERSION cuda-compat-10-1 \
                                               cuda-libraries-$CUDA_PKG_VERSION cuda-nvtx-$CUDA_PKG_VERSION libcublas10=10.2.1.243-1 \
                                               libnccl2=$NCCL_VERSION-1+cuda10.1 \
                                               cuda-nvml-dev-$CUDA_PKG_VERSION cuda-command-line-tools-$CUDA_PKG_VERSION \
                                               cuda-libraries-dev-$CUDA_PKG_VERSION cuda-minimal-build-$CUDA_PKG_VERSION \
                                               libnccl-dev=$NCCL_VERSION-1+cuda10.1 libcublas-dev=10.2.1.243-1 && \
    ln -s cuda-10.1 /usr/local/cuda && \
    apt-mark hold libnccl2 && \
    rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs

# RUNTIME AND DEVEL CUDNN7
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libcudnn7=$CUDNN_VERSION-1+cuda10.1 libcudnn7-dev=$CUDNN_VERSION-1+cuda10.1 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    NVIDIA_REQUIRE_CUDA="cuda>=10.1 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=439,driver<441"
COPY . ./TrWebOCR
RUN sed -i 's#http://deb.debian.org#https://mirrors.163.com#g' /etc/apt/sources.list \
    && apt update && apt install -y libglib2.0-dev libsm6 libxrender1 libxext-dev supervisor build-essential python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m pip install --upgrade pip
    && python3 -m pip install -r ./TrWebOCR/requirements.txt

RUN python3 -m pip install -r ./TrWebOCR/requirements.txt

RUN apt update && apt install -y libcublas10 
EXPOSE 8089
CMD ["supervisord","-c","/TrWebOCR/supervisord.conf"]


#CMD ["env", "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.2/lib64", ""]
