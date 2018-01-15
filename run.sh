#!/usr/bin/env bash

#
set -x

#docker pull dhnt/cf

# behind corporate firewall - http_proxy host needs to be ip address
# e.g. export http_proxy=http://10.10.10.10:8080

[ -z "$http_proxy" ] && proxy="" || proxy="-e http_proxy=$http_proxy -e https_proxy=$http_proxy -e no_proxy=$no_proxy"

#find local ip for X server
#required utils
#net-tools (ifconfig)
printf "ifconfig \n awk \n xset \n xhost \n" | xargs -n1 -I{} sh -c 'which {} || exit 255'; if [ $? -ne 0 ]; then
    exit 1
fi
##
#Ubuntu: socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CONNECT:/tmp/.X11-unix/X0
#
#Mac OSX: socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"
##
ipaddr=$(ifconfig | grep 'inet ' | grep -e '10\.' -e '172\.' -e '192\.'| awk '{$1=$1; print}'|cut -d' ' -f2 | cut -d: -f2 | xargs -n1 -I{} bash -c 'export DISPLAY={}:0; xset q 2>&1 > /dev/null && echo {} && exit 255;' 2> /dev/null)

export DISPLAY=${ipaddr}:0
xhost + $ipaddr

#
unix_name=$(uname -a)
case "${unix_name}" in
    *Microsoft* )
        echo "Windows 10 setup ..."
        export DHNT_BASE="/c/Users/liqiang/.dhnt"
    ;;
    *Darwin* )
        echo "Mac OSX setup ..."
        export DHNT_BASE=~/.dhnt
        export DISPLAY=unix:0
    ;;
    *Ubuntu* )
        echo "Ubuntu setup ..."
        export DHNT_BASE=~/.dhnt
        export DISPLAY=unix:0
    ;;
    *)
        echo "Default setup ..."
        export DHNT_BASE=~/.dhnt
esac

#
volume=""
[ -d "/private/tmp" ] && volume="$volume -v /private/tmp:/private/tmp"
[ -d "/tmp/.X11-unix" ] && volume="$volume -v /tmp/.X11-unix:/tmp/.X11-unix"

[ ! -z "${DHNT_VCAP_HOME}" ] && volume="$volume -v ${DHNT_VCAP_HOME}:/home/vcap"
[ ! -z "${GOPATH}" ] && volume="$volume -v ${GOPATH}:/home/vcap/go"

docker run $proxy $volume -e DISPLAY=${DISPLAY} -it --rm --privileged --name dhnt-cf-$$ dhnt/cf
#
