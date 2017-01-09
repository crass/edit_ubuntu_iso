#!/bin/bash
[ "$DEBUG" == "1" ] && set -x

# see: https://help.ubuntu.com/community/LiveCDCustomization
# see: https://wiki.ubuntu.com/CustomizeLiveInitrd

export PATH=$(readlink -f "$(dirname "$0")"):$PATH

ISO=$1
TMPDIR=${2:-/tmp/edit_iso.$$}
PWDORIG=$PWD

function cleanup() {
    cd "$PWDORIG"
    umount "$TMPDIR"/isomnt
    rm -r "$TMPDIR" /tmp/edit_iso
    exit 1
}

trap "echo 'cleaning up...'; cleanup" INT

mkdir -p "$TMPDIR"/isomnt
rm -f /tmp/edit_iso && ln -s "$TMPDIR" /tmp/edit_iso
sudo mount -o loop "$1" "$TMPDIR"/isomnt
cd "$TMPDIR"

read -p "Edit initrd... (y/n) [n]: " RESP
if [ "x$RESP" = "xy" ]; then
    INITRD=$(ls "isomnt/casper/initrd."*)
    edit_initrd.sh "$INITRD" "$(pwd)/$(basename "$INITRD")" || {
        ret=$?
        echo "Not generating iso"
        ( cleanup ) # do in subshell so we can return with the retcode we want
        exit $ret
    }

fi

read -p "Edit grub config... (y/n) [n]: " RESP
if [ "x$RESP" = "xy" ]; then
    cp isomnt/boot/grub/grub.cfg .
    sudo nano -w grub.cfg
fi

read -p "Edit grub loopback config... (y/n) [n]: " RESP
if [ "x$RESP" = "xy" ]; then
    cp isomnt/boot/grub/loopback.cfg .
    sudo nano -w loopback.cfg
fi

read -p "Edit disk defines... (y/n) [n]: " RESP
cp isomnt/README.diskdefines .
if [ "x$RESP" = "xy" ]; then
    chmod +w README.diskdefines
    nano -w README.diskdefines
    chmod -w README.diskdefines
fi

VOLID=$(grep DISKNAME README.diskdefines|(read _ _ R; f() { echo $1 $2 $6; }; eval f $R))
read -p "Enter ISO Volume Name (32 chars or less) [$VOLID]: " _VOLID
if [ -n "$_VOLID" ]; then
    VOLID=${_VOLID::32}
fi

INITRD=$(basename "isomnt/casper/initrd."*)
# regen the md5sum.txt
grep -v "README.diskdefines\|/$INITRD" isomnt/md5sum.txt > md5sum.txt
md5sum README.diskdefines "$INITRD" |
    sed -e 's|initrd|./casper/initrd|' \
        -e 's|README.diskdefines|./README.diskdefines|' >> md5sum.txt

( cd isomnt
# regen the iso
read -p "Enter iso name tag: " ISOTAG

# isolinux directory needs to be written to (boot.cat)
cp -r isolinux ..

for P in casper/* boot/grub/* *; do
    case "$P" in
        casper|casper/$INITRD) ;;
        README.diskdefines|md5sum.txt) ;;
        isolinux|isolinux/boot.cat) ;;
        boot|boot/grub/grub.cfg) ;;
        boot|boot/grub/loopback.cfg) ;;
        *) echo "$P=$P";;
    esac
done > ../path-list.txt
sudo mkisofs -D -r -V "$VOLID" -cache-inodes -J -l -graft-points \
    -b isolinux/isolinux.bin -c isolinux/boot.cat -x *boot.cat* \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o "$PWDORIG"/"$(basename "$ISO" .iso)"-"$ISOTAG".iso \
    -path-list ../path-list.txt \
    casper/$INITRD=../$INITRD \
    boot/grub/grub.cfg=../grub.cfg \
    boot/grub/loopback.cfg=../loopback.cfg \
    README.diskdefines=../README.diskdefines \
    md5sum.txt=../md5sum.txt \
    isolinux=../isolinux || (echo "failed see what happened..." && bash)
)

cleanup
