This project was initially created to add encryption to the persistent storage
capability of the official iso.  See the original blog post for the 13.04 iso:

> https://archimedesden.wordpress.com/2013/09/12/encrypted-persistent-storage-on-ubuntu-livecd/

And for an updated post for 16.10 see:

> https://archimedesden.wordpress.com/2017/01/09/encrypted-persistent-ubuntu-livecd-16-10-redux

# Patching the official iso
In the [patches](patches) directory there are xdeltas to patch a corresponding official
iso.  These patch files will add various capabilities to the official iso.
For example, ubuntu-16.10-desktop-amd64-encrypt-persist.xdelta adds the
ability to encrypt the persistent storage and adds a grub option for booting
into the persistent storage.  For example,

```
xdelta patch ubuntu-16.10-desktop-amd64-encrypt-persist.xdelta \
             ubuntu-16.10-desktop-amd64.iso ubuntu-16.10-desktop-amd64-persist.iso
```
