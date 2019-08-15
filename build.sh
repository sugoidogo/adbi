#!/bin/sh
dub build --single adbi.d
upx --best bin/linux/x86_64/adbi
