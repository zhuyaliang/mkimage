#!/bin/bash

repopath="http://192.168.39.230/centos8/isoft/RPMS/"
sqlite="d4ac5c1e438377b1a701dbf086fe291d2c3007c3ef2d275f33e3824564abb994-primary.sqlite"
fsdir=rootfs-$(date +%s)
env_check()
{
    cmd_list="rpm2cpio wget tar docker sqlite3 bunzip2 git" 
    for cmd in ${cmd_list[@]}; do
	    which "$cmd" >/dev/null 2>&1
	    if [ $? -ne 0 ]; then
            echo -e "\033[5;31m $cmd \033[0m"
            echo -e "\033[4;31m $cmd Command does not exist, please install this command\033[0m"
            exit
        fi
    done
}
down_pkg()
{
#    git clone https://github.com/zhuyaliang/mkimage
    rm -rf org_env
    mkdir org_env 
    cd org_env
    cat ../mkimage/pkg.list |while read pkg
    do
        pkgpath=$(sqlite3 ../$sqlite "select location_href from packages where name='$pkg'")
        if [ -n "$pkgpath" ]; then
            echo $pkgpath
            wget $repopath$pkgpath
        fi
    done
}
unpacking_rpm()
{
    for pkg in $(ls *.rpm);
    do
        rpm2cpio $pkg | cpio -div
    done
    /usr/bin/cp -rfa lib64/* usr/lib64/
    cp -rf ../mkimage/libdnf.so*  usr/lib64/
    cd usr/lib64/
    unlink libcurl.so.4
    ln -s libcurl.so.4.5.0 libcurl.so.4
    cd -
    rm -rf lib64
    ln -s usr/lib64/ lib64 
    cd ../
}
create_rootfs_env()
{
    list="bash ls microdnf"
    mkdir -p $fsdir/bin $fsdir/usr/ $fsdir/usr/bin/ $fsdir/usr/lib/rpm  $fsdir/usr/lib64 $fsdir/etc/pki $fsdir/proc
    ln -sf usr/lib64 $fsdir/lib64
    rm -rf $fsdir/lib
    ln -sf usr/lib $fsdir/lib
    for i in $list
    do
        cp -raf "mkimage/"$i "${fsdir}/usr/bin/"
    done
    
    cat ./mkimage/lib.list |while read line
    do
        lib="org_env"$line
        link="$(readlink $lib -f)"
        cp -rfa "$lib" "${fsdir}${line}"
        cp -rfa "$link" "${fsdir}/usr/lib64/"
    done
    
    cp -rf org_env/etc/os-release  $fsdir/etc/.
    cp -rf org_env/usr/lib/rpm/rpmrc $fsdir/usr/lib/rpm/
    cp -rf org_env/usr/lib/rpm/macros $fsdir/usr/lib/rpm/
    cp -rf org_env/etc/pki/rpm-gpg $fsdir/etc/pki/

    rm -rf $fsdir/bin/
    cd $fsdir
    ln -s usr/bin bin

}
create_image_repo()
{
    mkdir etc/yum.repos.d/ -p
    touch etc/yum.repos.d/image_aarch64.repo
    echo [openEuler] >> etc/yum.repos.d/image_aarch64.repo 
    echo name=openEuler >> etc/yum.repos.d/image_aarch64.repo
    echo baseurl=$repopath >> etc/yum.repos.d/image_aarch64.repo
    echo gpgcheck=0 >> etc/yum.repos.d/image_aarch64.repo
    echo gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-openEuler >> etc/yum.repos.d/image_aarch64.repo
    echo priority=1 >> etc/yum.repos.d/image_aarch64.repo
    cd ../
}
create_docker_image()
{
    sudo tar -C $fsdir -c . | sudo docker import - new_aarch64_os:latest
}
#main

env_check
down_pkg
unpacking_rpm
create_rootfs_env
create_image_repo
create_docker_image
