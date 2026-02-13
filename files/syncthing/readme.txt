https://docs.syncthing.net/users/releases.html
v1.23.1  go1.19.5  2023-01-16
go version bellow 1.19 suite for kernel 4.4.35

wget https://github.com/syncthing/syncthing/releases/download/v1.23.1/syncthing-linux-arm64-v1.23.1.tar.gz
tar xzf syncthing-linux-arm64-v1.23.1.tar.gz
cd syncthing-linux-arm64-v1.23.1
cp -r etc/linux-systemd/system /lib/systemd/
cp -r etc/linux-systemd/user /lib/systemd/
cp etc/linux-sysctl/30-syncthing.conf /etc/sysctl.d/
sysctl -q --system
cp syncthing /usr/bin/
systemctl enable syncthing@username
systemctl start syncthing@username
