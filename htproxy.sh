#!/bin/bash
# ...existing code...

random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
    echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
    ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
    }
    echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
    echo "installing 3proxy"
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    wget -qO- "$URL" | bsdtar -xvf-
    cd 3proxy-3proxy-0.8.6 || return 1
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/bin
    mkdir -p /usr/local/etc/3proxy/logs
    mkdir -p /usr/local/etc/3proxy/stat
    cp src/3proxy /usr/local/etc/3proxy/bin/
    if [ -f ./scripts/rc.d/proxy.sh ]; then
        cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
        chmod +x /etc/init.d/3proxy
        # enable init.d script on Ubuntu
        update-rc.d 3proxy defaults 2>/dev/null || true
    fi
    cd "$WORKDIR" || return 1
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 1000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' "${WORKDATA}")

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' "${WORKDATA}")
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' "${WORKDATA}")
EOF
}

upload_proxy() {
    local PASS
    PASS=$(random)
    zip --password "$PASS" proxy.zip proxy.txt >/dev/null 2>&1
    URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"
}

gen_data() {
    seq "$FIRST_PORT" "$LAST_PORT" | while read -r port; do
        echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 "$IP6")"
    done
}

gen_iptables() {
    cat <<EOF
$(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' "${WORKDATA}")
EOF
}

detect_iface() {
    # detect primary outbound interface (IPv4) or first non-loopback UP interface
    IFACE=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')
    if [ -z "$IFACE" ]; then
        IFACE=$(ip -o link show up | awk -F': ' '$2 !~ /lo/ {print $2; exit}')
    fi
    : "${IFACE:=eth0}"
    echo "$IFACE"
}

gen_ifconfig() {
    IFACE_DET=$(detect_iface)
    cat <<EOF
$(awk -F "/" -v IFACE="$IFACE_DET" '{print "ip -6 addr add " $5 "/64 dev " IFACE}' "${WORKDATA}")
EOF
}

echo "installing apps"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1
    apt-get install -y gcc net-tools bsdtar zip wget curl iproute2 iptables >/dev/null 2>&1
else
    # fallback to yum if present
    yum -y install gcc net-tools bsdtar zip wget curl iproute iptables >/dev/null 2>&1 || true
fi

install_3proxy

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir -p "$WORKDIR" && cd "$WORKDIR" || exit 1

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. External sub for ip6 = ${IP6}"

echo "How many proxy do you want to create? Example 500"
read -r COUNT

FIRST_PORT=10000
LAST_PORT=$((FIRST_PORT + COUNT))

gen_data >"${WORKDATA}"
gen_iptables >"${WORKDIR}/boot_iptables.sh"
gen_ifconfig >"${WORKDIR}/boot_ifconfig.sh"
chmod +x "${WORKDIR}/boot_"*.sh /etc/rc.local 2>/dev/null || true

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

# ensure /etc/rc.local exists and is executable (Ubuntu compatibility)
if [ ! -f /etc/rc.local ]; then
    cat > /etc/rc.local <<'RCINIT'
#!/bin/bash
exit 0
RCINIT
    chmod +x /etc/rc.local
fi

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF

bash /etc/rc.local || true

gen_proxy_file_for_user

upload_proxy
# ...existing code...
```// filepath: /workspaces/3proxy/htproxy.sh
#!/bin/bash
# ...existing code...

random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
    echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
    ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
    }
    echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
    echo "installing 3proxy"
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    wget -qO- "$URL" | bsdtar -xvf-
    cd 3proxy-3proxy-0.8.6 || return 1
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/bin
    mkdir -p /usr/local/etc/3proxy/logs
    mkdir -p /usr/local/etc/3proxy/stat
    cp src/3proxy /usr/local/etc/3proxy/bin/
    if [ -f ./scripts/rc.d/proxy.sh ]; then
        cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
        chmod +x /etc/init.d/3proxy
        # enable init.d script on Ubuntu
        update-rc.d 3proxy defaults 2>/dev/null || true
    fi
    cd "$WORKDIR" || return 1
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 1000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' "${WORKDATA}")

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' "${WORKDATA}")
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' "${WORKDATA}")
EOF
}

upload_proxy() {
    local PASS
    PASS=$(random)
    zip --password "$PASS" proxy.zip proxy.txt >/dev/null 2>&1
    URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"
}

gen_data() {
    seq "$FIRST_PORT" "$LAST_PORT" | while read -r port; do
        echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 "$IP6")"
    done
}

gen_iptables() {
    cat <<EOF
$(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' "${WORKDATA}")
EOF
}

detect_iface() {
    # detect primary outbound interface (IPv4) or first non-loopback UP interface
    IFACE=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')
    if [ -z "$IFACE" ]; then
        IFACE=$(ip -o link show up | awk -F': ' '$2 !~ /lo/ {print $2; exit}')
    fi
    : "${IFACE:=eth0}"
    echo "$IFACE"
}

gen_ifconfig() {
    IFACE_DET=$(detect_iface)
    cat <<EOF
$(awk -F "/" -v IFACE="$IFACE_DET" '{print "ip -6 addr add " $5 "/64 dev " IFACE}' "${WORKDATA}")
EOF
}

echo "installing apps"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1
    apt-get install -y gcc net-tools bsdtar zip wget curl iproute2 iptables >/dev/null 2>&1
else
    # fallback to yum if present
    yum -y install gcc net-tools bsdtar zip wget curl iproute iptables >/dev/null 2>&1 || true
fi

install_3proxy

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir -p "$WORKDIR" && cd "$WORKDIR" || exit 1

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. External sub for ip6 = ${IP6}"

echo "How many proxy do you want to create? Example 500"
read -r COUNT

FIRST_PORT=10000
LAST_PORT=$((FIRST_PORT + COUNT))

gen_data >"${WORKDATA}"
gen_iptables >"${WORKDIR}/boot_iptables.sh"
gen_ifconfig >"${WORKDIR}/boot_ifconfig.sh"
chmod +x "${WORKDIR}/boot_"*.sh /etc/rc.local 2>/dev/null || true

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

# ensure /etc/rc.local exists and is executable (Ubuntu compatibility)
if [ ! -f /etc/rc.local ]; then
    cat > /etc/rc.local <<'RCINIT'
#!/bin/bash
exit 0
RCINIT
    chmod +x /etc/rc.local
fi

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF

bash /etc/rc.local || true

gen_proxy_file_for_user

upload_proxy
# ...existing code...
