mkdir -p root
mount linux/rootfs.ext4 root
cd root/root
cp -r ../../shared .
cd ../../
umount root
rm -rf root
exit
