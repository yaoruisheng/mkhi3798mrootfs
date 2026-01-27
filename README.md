安装cloudflared 后 chroot 模式安装其服务需要先执行mkdir -p /run/systemd/system，不然会以sysvinit模式安装。
