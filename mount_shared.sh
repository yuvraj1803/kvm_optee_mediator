set -e
mkdir -p root
mount linux/rootfs.ext4 root
cd root/root
rm -rf shared
cp -r ../../shared .
cd ../../
umount root
rm -rf root
exit
