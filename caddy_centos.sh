#!/bin/bash
domain=$1
email=$2
proxy_site=$3
path=$4
v2ray_port=$5
echo $domain $email $proxy_site $path $v2ray_port
_download_caddy_file() {
	echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" | sudo tee -a /etc/apt/sources.list.d/caddy-fury.list
	yum install apt-transport-https
	yum update
	yum install caddy
	if [[ ! -f /usr/bin/caddy ]]; then
		echo -e "$red 安装 Caddy 出错！$none" && exit 1
	fi
}
_install_caddy_service() {
	# setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy
        systemd=1
	if [[ $systemd ]]; then
		# cp -f ${caddy_tmp}init/linux-systemd/caddy.service /lib/systemd/system/
		# # sed -i "s/www-data/root/g" /lib/systemd/system/caddy.service
		# sed -i "/on-abnormal/a RestartSec=3" /lib/systemd/system/caddy.service
		# sed -i "s/on-abnormal/always/" /lib/systemd/system/caddy.service

		#### 。。。。。 Warning.....Warning.......Warning........Warning......
		#### 。。。。。 use root user run caddy...

		cat >/lib/systemd/system/caddy.service <<-EOF
			[Unit]
			Description=Caddy HTTP/2 web server
			Documentation=https://caddyserver.com/docs
			After=network.target
			Wants=network.target
			
			[Service]
			Restart=always
			RestartSec=3
			Environment=CADDYPATH=/root/.caddy
			ExecStart=/usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile -root=/var/tmp
			ExecReload=/bin/kill -USR1 $MAINPID
			KillMode=mixed
			KillSignal=SIGQUIT
			TimeoutStopSec=5s
			LimitNOFILE=1048576
			LimitNPROC=512
			
			[Install]
			WantedBy=multi-user.target
		EOF
		systemctl enable caddy
	else
		cp -f ${caddy_tmp}init/linux-sysvinit/caddy /etc/init.d/caddy
		# sed -i "s/www-data/root/g" /etc/init.d/caddy
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi

	# if [ -z "$(grep www-data /etc/passwd)" ]; then
	# 	useradd -M -s /usr/sbin/nologin www-data
	# fi
	# chown -R www-data.www-data /etc/ssl/caddy

	# ref https://github.com/caddyserver/caddy/tree/master/dist/init/linux-systemd

	mkdir -p /etc/caddy
	# chown -R root:root /etc/caddy
	# mkdir -p /etc/ssl/caddy
	# chown -R root:www-data /etc/ssl/caddy
	# chmod 0770 /etc/ssl/caddy

	## create sites dir
	mkdir -p /etc/caddy/sites
}

main(){
    _download_caddy_file
    # _install_caddy_service
    cat >/etc/caddy/Caddyfile <<-EOF
${domain} {
    tls ${email}
    encode gzip
    reverse_proxy / ${proxy_site}   
    reverse_proxy /${path} 127.0.0.1:${v2ray_port}
}
import sites/*
		EOF
}
main
