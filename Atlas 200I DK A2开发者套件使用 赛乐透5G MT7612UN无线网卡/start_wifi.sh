#!/bin/bash
exec > /home/HwHiAiUser/wifi_debug.log 2>&1
set -x

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

killall hostapd || true
# 把之前的旧 DHCP 进程也杀掉
killall dnsmasq || true
rmmod brcmfmac brcmutil || true
sleep 2

insmod /home/HwHiAiUser/brcmutil.ko
insmod /home/HwHiAiUser/brcmfmac.ko

WIFI_IF=""
for i in {1..15}; do
    if ip link show wlan0 > /dev/null 2>&1; then
        WIFI_IF="wlan0"
        break
    elif ip link show wlxac83f3669f60 > /dev/null 2>&1; then
        WIFI_IF="wlxac83f3669f60"
        break
    fi
    sleep 1
done

if [ -n "$WIFI_IF" ]; then
    ip link set $WIFI_IF up
    ip addr flush dev $WIFI_IF
    ip addr add 192.168.66.1/24 dev $WIFI_IF
    
    # 【新增灵魂核心】：在指定网卡上拉起 DHCP 服务，发牌范围 10~100
    dnsmasq -i $WIFI_IF -p 0 -F 192.168.66.10,192.168.66.100,255.255.255.0,12h -O 3,192.168.66.1 -O 6,114.114.114.114

    sed -i "s/^interface=.*/interface=$WIFI_IF/" /home/HwHiAiUser/pure_ap.conf
    exec hostapd /home/HwHiAiUser/pure_ap.conf
fi
