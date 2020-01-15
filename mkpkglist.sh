#!/bin/bash
list="microdnf bash"
for i in $list
do
    base=`which $i`
    NIX="$(ldd $base |sed 's/=>/ /g'|  egrep -o '/.*/lib.*\.[0-9].s*o*')"
    for a in $NIX
    do
	PKG="$(rpm -qf $a --qf "%{Name}\n")"
        echo -e "$PKG" >> ./tmp.list
        echo -e "$a" >> ./lib.list	
    done
done
cat ./tmp.list | sort -k2n | uniq > ./pkg.list
rm -rf ./tmp.list
#cp -rf /usr/lib64/liblua-5.3.so $dir/usr/lib64/
#cp -rf /usr/lib64/libdb-5.3.so $dir/usr/lib64/
#cp -rf /usr/lib64/libsecurec.so $dir/usr/lib64/
#
#cp -rf /etc/os-release  $dir/etc/.
#cp -rf /etc/yum.repos.d/ $dir/etc/
#cp -rf /usr/lib/rpm/rpmrc $dir/usr/lib/rpm/
#cp -rf /usr/lib/rpm/macros $dir/usr/lib/rpm/
#cp -rf /etc/pki/rpm-gpg $dir/etc/pki/
#
#/usr/bin/cp -rf $dir/lib64/* $dir/usr/lib64/
#/usr/bin/cp -rf $dir/lib/* $dir/usr/lib/
#
#rm -rf $dir/lib64/
#rm -rf $dir/bin/
#rm -rf $dir/lib/
#cd $dir
#ln -s usr/bin bin
#ln -s usr/lib64 lib64
#ln -s usr/lib lib
#mount --bind /proc/ proc/
#chroot .
