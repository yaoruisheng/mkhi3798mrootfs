#!/bin/bash

GREEN=40
RED=41
IFACE="eth0"
CHECK_IP=223.5.5.5

# 检测间隔（可调）
INTERVAL_OK=10      # 网络正常
INTERVAL_FAIL=60    # 网络不通（省电）

FAIL_THRESHOLD=2    # 连续失败次数才判红

POLL_PID=""
POLLING=0

init_gpio() {
    echo $GREEN > /sys/class/gpio/export 2>/dev/null
    echo out > /sys/class/gpio/gpio$GREEN/direction

    echo $RED > /sys/class/gpio/export 2>/dev/null
    echo out > /sys/class/gpio/gpio$RED/direction
}

green_on() {
    echo 255 > /sys/class/gpio/gpio$GREEN/value
    echo 0 > /sys/class/gpio/gpio$RED/value
}

red_on() {
    echo 0 > /sys/class/gpio/gpio$GREEN/value
    echo 255 > /sys/class/gpio/gpio$RED/value
}

check_net() {
    ping -c1 -W1 $CHECK_IP >/dev/null 2>&1
}

start_polling() {
    if [ "$POLLING" -eq 1 ]; then
        return
    fi

    POLLING=1

    setsid bash -c "
        FAIL=0
        STATE=unknown

        while true; do
            if ping -c1 -W1 $CHECK_IP >/dev/null 2>&1; then
                FAIL=0
                if [ \"\$STATE\" != \"green\" ]; then
                    echo 255 > /sys/class/gpio/gpio$GREEN/value
                    echo 0 > /sys/class/gpio/gpio$RED/value
                    STATE=green
                fi
                sleep $INTERVAL_OK
            else
                FAIL=\$((FAIL+1))

                if [ \$FAIL -ge $FAIL_THRESHOLD ]; then
                    if [ \"\$STATE\" != \"red\" ]; then
                        echo 0 > /sys/class/gpio/gpio$GREEN/value
                        echo 255 > /sys/class/gpio/gpio$RED/value
                        STATE=red
                    fi
                    sleep $INTERVAL_FAIL
                else
                    sleep $INTERVAL_OK
                fi
            fi
        done
    " &
    
    POLL_PID=$!
}

stop_polling() {
    POLLING=0
    if [ -n "$POLL_PID" ]; then
        kill -9 -"$POLL_PID" 2>/dev/null
        POLL_PID=""
    fi
}

trap 'stop_polling; exit' INT TERM

init_gpio

# 初始化状态
state=$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)

if [ "$state" = "down" ]; then
    red_on
else
    if check_net; then
        green_on
    else
        red_on
    fi
    start_polling
fi

# 事件驱动监听链路
ip monitor link | while read -r line; do
    echo "$line" | grep -q "$IFACE" || continue

    state=$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)

    if [ "$state" = "down" ]; then
        red_on
        stop_polling
        continue
    fi

    # link up → 先快速检测一次
    if check_net; then
        green_on
    else
        red_on
    fi

    start_polling
done
