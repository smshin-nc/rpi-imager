#!/bin/bash
#set -e

ARCH=arm64
SUITE=jammy
MIRROR=rootfs-arm64-1.1.0

# standard 설치
sudo debootstrap --arch=$ARCH --variant=standard --print-debs $SUITE $MIRROR > standard.txt

# minbase 설치
sudo debootstrap --arch=$ARCH --variant=minbase --print-debs $SUITE $MIRROR > minbase.txt

# 차이 확인
diff minbase.txt standard.txt
