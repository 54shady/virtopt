# Make Debug Suckless

## 允许ssh使用root用户登入(/etc/ssh/sshd_config)

	PermitRootLogin yes
	RSAAuthentication yes
	PubkeyAuthentication yes

## 设置图形界面root自动登入

设置root密码

	passwd root

修改/etc/lightdm/lightdm.conf

	[Seat:*]
	autologin-guest=false
	autologin-user=root
	autologin-user-timeout=0
	greeter-session=lightdm-gtk-greeter

修改~/.profile

	# ~/.profile: executed by Bourne-compatible login shells.

	if [ "$BASH" ]; then
	  if [ -f ~/.bashrc ]; then
		. ~/.bashrc
	  fi
	fi

	tty -s && mesg n || true

## 主机端同步调试机(172.20.101.124)的代码

客户端配置rsync(/etc/default/rsync)

	RSYNC_ENABLE=true

复制配置文件

	cp /usr/share/doc/rsync/examples/rsyncd.conf /etc


修改配置文件(/etc/rsyncd.conf)

	[ftp]

		comment = public archive
		path = /usr/src/linux
		use chroot = yes
		lock file = /var/lock/rsyncd
		read only = yes
		list = yes
		uid = nobody
		gid = nogroup
		strict modes = yes
		ignore errors = no
		ignore nonreadable = yes
		transfer logging = no
		timeout = 600
		refuse options = checksum dry-run
		dont compress = *.gz *.tgz *.zip *.z *.rpm *.deb *.iso *.bz2 *.tbz

启动rsync服务

	/etc/init.d/rsync start

主机端同步代码

	cp exclude_list /tmp/
	rsync -vzurtopg --progress --delete --exclude-from=/tmp/exclude_list 172.20.101.124::ftp ./

	ln -s scripts/gdb/vmlinux-gdb.py
