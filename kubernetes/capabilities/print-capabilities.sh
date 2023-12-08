#/bin/sh

set -x

grep Cap /proc/1/status

capsh --print

./captest
