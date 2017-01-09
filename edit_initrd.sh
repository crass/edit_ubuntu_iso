#!/bin/bash
set -x

# see: https://help.ubuntu.com/community/LiveCDCustomization
# see: https://wiki.ubuntu.com/CustomizeLiveInitrd
TMP=${TMP:-/tmp}

INITRD=$(readlink -f "$1")
INITRDDIR="$TMP/$(basename "$INITRD").d"
OFILE=${2:-"$TMP/$(basename "$INITRD")"}
if [ -e "$OFILE" ]; then
    OFILE="${OFILE}.1"
fi

COMPRESS_LEVEL=${COMPRESS_LEVEL:=-7}

mkdir -p "$INITRDDIR"
(
    cd "$INITRDDIR"
#    CPROG="xz --format=lzma"
    case "$INITRD" in
        *lz) CPROG="xz --format=lzma";; # must be lzma format
        *xz) CPROG=xz;;
        *bz2) CPROG=bzip2;;
        *gz) CPROG=gzip;;
        # Many times the initrd has no file extension
        *) case "$(file -b "$INITRD")" in
              LZMA*) CPROG="xz --format=lzma";; # must be lzma format
              XZ*) CPROG="xz";;
              bzip2*) CPROG=bzip2;;
              gzip*) CPROG=gzip;;
              *) CPROG=: "$(file -b "$INITRD")";;
           esac
    esac
    $CPROG -d -c < "$INITRD" | cpio -i --no-absolute-filenames
    
    echo "edit the initrd now..."
    bash || exit $? 
    
    find . | cpio --quiet --dereference -o -H newc |
      $CPROG -c "$COMPRESS_LEVEL" > "$OFILE"
) || {
    ret=$?
    echo "Failure not generating initrd"
    exit $ret
}
rm -r "$INITRDDIR"
