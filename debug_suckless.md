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

## Build minimal system stage4 tarball

Using [script gen_stage4.sh](gen_stage4.sh) for ubuntu 16.04 minimal system backup and migration

cd to top root and run script(backup)

	cd /
	./gen_stage4.sh

deploy the stage4 tarball(install system)

	tar jxvf stage4.tar.bz2 -C /

## 分布式编译

[参考:distcc加速内核编译](https://blog.csdn.net/weixin_30439067/article/details/96560971)

- 编译主机L
- 加速编译主机A,B,C...(compile farm)

假设L,A,B,C都在局域网172.20.x.x中

主机L上安装软件

	apt install distcc distccmon-gnome distcc-pump

主机farm上安装软件

	apt install distcc

所有机器都使用配置文件(/etc/default/distcc)

	STARTDISTCC="true"
	ALLOWEDNETS="127.0.0.1 172.20.0.0/16"
	LISTENER=""
	NICE="10"
	JOBS=""
	ZEROCONF="false"

重启distcc服务

	systemctl restart distcc

此时在任何一台机器上执行(distcc --show-hosts)

	172.20.101.124:3632/16
	172.20.101.101:3632/16

修改每台机器的(/etc/distcc/hosts)将上面的结果填入并
并注释调zeroconf,添加cpp,lzo

	#+zeroconf
	172.20.101.124:3632/16,cpp,lzo
	172.20.101.101:3632/16,cpp,lzo

在L机器上编译内核

	distcc-pump make -j$(distcc -j) CC="distcc ${CROSS_COMPILE}gcc"

在L机器上编译内核(带参数)

	distcc-pump make -j$(distcc -j) CFLAGS_vmx.o='-O0 -ftree-ter' CFLAGS_kvm.o='-O0 -ftree-ter' CC="distcc ${CROSS_COMPILE}gcc"

## make ubuntu ISO

[参考: LiveCDCustomization](https://help.ubuntu.com/community/LiveCDCustomization)

挂载基础ISO,拷贝所有文件到到extract-cd

	mount -o loop /path/to/ubuntu-16.04.4-desktop-amd64.iso /media/
	rsync -a /media/ /tmp/extract-cd

制作rootfs

	cd /tmp
	unsquashfs /media/casper/filesystem.squashfs
	mv squashfs-root edit

	tar jxvf /path/to/stage4.tar.bz2 -C /tmp/edit
	rm /tmp/extract-cd/casper/filesystem.squashfs
	mksquashfs edit /tmp/extract-cd/casper/filesystem.squashfs -b 1048576

更新文件系统信息

	printf $(du -sx --block-size=1 edit | cut -f1) > /tmp/extract-cd/casper/filesystem.size

	cd /tmp/extract-cd/
	rm md5sum.txt
	find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

制作ISO文件

	cd /tmp/extract-cd
	mkisofs -D -r -V "myubuntu" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-desktop-custom.iso .
