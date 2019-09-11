#!/bin/sh
cd $(dirname $BASH_SOURCE)/..
dub build --single src/adbi.d 
dub build --single src/common.d
upx --best bin/linux/x86_64/adbi
upx --best bin/linux/x86_64/common
mksiofs -o bin/linux.iso bin/linux/x86_64
cat res/stub.sh bin/linux.iso > adbi.d