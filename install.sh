#!/bin/bash

pkill -f v2ray
pkill -f filebrow
pkill -f caddy
rm -rf /v2ok

apt update
apt install -y dos2unix wget zip unzip
echo "input zip password: "
read PASSWD
echo "Input Domain: [a.b.c.d]\n"
read VDOMAIN

wget https://github.com/wlya/v3/raw/main/v2ok2.zip
unzip -P $PASSWD -o v2ok2.zip -d /v2ok/
unzip -P $PASSWD -o /v2ok/v2ok.zip -d /v2ok/
mkdir -p /v2ok/httproot/

cat > /v2ok/caddy.conf <<EOF
$VDOMAIN {    
    reverse_proxy /one localhost:10000
}
EOF

echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p


curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/rc.local <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
# bash /root/bindip.sh

/v2ok/caddy_linux_amd64 run -config /v2ok/caddy.conf  --adapter caddyfile &
/v2ok/v2ray-linux-64/v2ray -config /v2ok/config.json &
filebrowser -r /v2ok/httproot &
exit 0
EOF
chmod a+x /etc/rc.local
dos2unix /etc/rc.local

systemctl enable rc-local
systemctl start rc-local.service

nohup sh /etc/rc.local &

