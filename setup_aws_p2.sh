#!/bin/sh
#
# Provisioning script for AWS P2 instances.
#
# Tested on instance p2.xlarge with Amazon Linux AMI 2017.09.1 (HVM).
#
# cuDNN (v6.0 for CUDA 8.0) should be downloaded manually from
#  developer.nvidia.com and uploaded to a S3 bucket.
S3_BUCKET="cudnn-7a2cdcbc8755891a"

yum update -y
yum install -y python36-pip gcc kernel-devel htop
python36 -m pip install -r requirements.txt --upgrade
python36 -m nltk.downloader all

test -f /tmp/NVIDIA-Linux-x86_64-367.106.run \
	|| wget -O /tmp/NVIDIA-Linux-x86_64-367.106.run http://us.download.nvidia.com/XFree86/Linux-x86_64/367.106/NVIDIA-Linux-x86_64-367.106.run

test -f /usr/bin/nvidia-smi \
	|| /bin/bash /tmp/NVIDIA-Linux-x86_64-367.106.run -a -s

test -f /tmp/cuda_8.0.61_375.26_linux-run \
	|| wget -O /tmp/cuda_8.0.61_375.26_linux-run https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run

test -f /usr/local/cuda/bin/nvcc \
	|| sh /tmp/cuda_8.0.61_375.26_linux-run --silent --toolkit

test -f /tmp/cudnn-8.0-linux-x64-v6.0.tgz \
	|| aws s3 cp s3://$S3_BUCKET/cudnn-8.0-linux-x64-v6.0.tgz /tmp/.

cd /usr/local
test -f cuda/lib64/libcudnn.so \
	|| tar xvzf /tmp/cudnn-8.0-linux-x64-v6.0.tgz
cd -

echo export PATH="$PATH:/usr/local/cuda/bin:/usr/local/bin/" > /etc/profile.d/cuda.sh
echo export LD_LIBRARY_PATH="/usr/local/cuda/lib64" >> /etc/profile.d/cuda.sh