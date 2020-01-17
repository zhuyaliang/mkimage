#!/bin/bash

repopath1="http://119.3.219.20:8080/Mainline/standard_aarch64/"
repopath2="http://119.3.219.20:8080/Extras/standard_aarch64/"
fsdir=rootfs-$(date +%s)
org_dir=org_dir-$(date +%s)
work_dir=$(pwd)
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
    echo "Download package...."
    mkdir /tmp/$org_dir 
    ./dl_pkg.py pkg.list /tmp/$org_dir
    echo "Download package successful"
}
unpacking_rpm()
{
    cd /tmp/$org_dir/
    echo "Unpacking ...."
    for pkg in $(ls *.rpm);
    do
        rpm2cpio $pkg | cpio -div >> /dev/null 2>&1 
    done
    echo "Unpacking successful"
    /usr/bin/cp -rfa lib64/* usr/lib64/
    cp -rf $work_dir/libdnf.so*  usr/lib64/
    cp -rf $work_dir/microdnf usr/bin/
    cp -rf $work_dir/httpd usr/bin/
    cp -rf $work_dir/httpd.conf .
    cp -rf $work_dir/libpeas-1.0.so.0 usr/lib64/
    cd usr/lib64/
    unlink libcurl.so.4
    ln -s libcurl.so.4.5.0 libcurl.so.4
    cd -
    rm -rf lib64
    ln -s usr/lib64/ lib64 
}
create_rootfs_env()
{
    cd /tmp/
    echo "Create rootfs"
    list="bash ls microdnf vim"
    mkdir -p $fsdir/bin $fsdir/usr/ $fsdir/root/ $fsdir/usr/bin/ $fsdir/usr/lib/rpm  $fsdir/usr/lib64 $fsdir/etc/pki $fsdir/proc $fsdir/usr/share/terminfo/x/
    ln -sf usr/lib64 $fsdir/lib64
    rm -rf $fsdir/lib
    ln -sf usr/lib $fsdir/lib

    #复制二进制
    for i in $list
    do
        cp -raf $org_dir/usr/bin/$i "${fsdir}/usr/bin/"
    done
    #复制二进制需要的动态库    
    cat $work_dir/lib.list |while read line
    do
        lib=$org_dir$line
        link="$(readlink $lib -f)"
        cp -rfa "$lib" "${fsdir}${line}"
        cp -rfa "$link" "${fsdir}/usr/lib64/"
    done
    #复制dnf 需要的配置文件
    cp -rf $org_dir/etc/os-release  $fsdir/etc/.
    cp -rf $org_dir/usr/lib/rpm/rpmrc $fsdir/usr/lib/rpm/
    cp -rf $org_dir/usr/lib/rpm/macros $fsdir/usr/lib/rpm/
    cp -rf $org_dir/etc/pki/rpm-gpg $fsdir/etc/pki/
	
    #复制vim 需要的配置文件
    cp -rf $org_dir/usr/share/terminfo/x/xterm $fsdir/usr/share/terminfo/x/
    
    rm -rf $fsdir/bin/
    cd $fsdir
    ln -s usr/bin bin
    cd bin
    ln -s microdnf yum 
    ln -s bash sh
    cd ../
    echo "Create rootfs successful"
}
create_image_repo()
{
    mkdir etc/yum.repos.d/ -p
    touch etc/yum.repos.d/image_aarch64.repo

    echo [openEuler1] >> etc/yum.repos.d/image_aarch64.repo 
    echo name=mainline >> etc/yum.repos.d/image_aarch64.repo
    echo baseurl=$repopath1 >> etc/yum.repos.d/image_aarch64.repo
    echo enabled=1 >> etc/yum.repos.d/image_aarch64.repo
    echo gpgcheck=0 >> etc/yum.repos.d/image_aarch64.repo
    
    echo [openEuler2] >> etc/yum.repos.d/image_aarch64.repo 
    echo name=extras  >> etc/yum.repos.d/image_aarch64.repo
    echo baseurl=$repopath2 >> etc/yum.repos.d/image_aarch64.repo
    echo enabled=1 >> etc/yum.repos.d/image_aarch64.repo
    echo gpgcheck=0 >> etc/yum.repos.d/image_aarch64.repo
    cd ../
}
create_httpd_env()
{
    cp -raf $org_dir/usr/bin/httpd "${fsdir}/usr/bin/httpdd"
    cp -raf $org_dir/usr/bin/tail "${fsdir}/usr/bin/"
    cp -rfa $org_dir/usr/lib64/libaprutil-1.so.0* "${fsdir}/usr/lib64/"
    cp -rfa $org_dir/usr/lib64/libexpat.so.1* "${fsdir}/usr/lib64/"
    cp -rfa $org_dir/usr/lib64/libapr-1.so.0* "${fsdir}/usr/lib64/"
    
    mkdir -p $fsdir/modules $fsdir/logs $fsdir/conf
    cp -rfa $org_dir/usr/lib64/httpd/modules/mod_authn_core.so "${fsdir}/modules/"
    cp -rfa $org_dir/usr/lib64/httpd/modules/mod_authz_core.so "${fsdir}/modules/"
    cp -rfa $org_dir/usr/lib64/httpd/modules/mod_dir.so "${fsdir}/modules/"
    cp -rfa $org_dir/usr/lib64/httpd/modules/mod_unixd.so "${fsdir}/modules/"
    cp -rfa $org_dir/usr/share/httpd/noindex/index.html "${fsdir}/"

    cp -rfa $org_dir/httpd.conf "$fsdir/conf/"
    echo "/bin/httpdd" >> "${fsdir}/usr/bin/httpd"
    echo "tail" >> "${fsdir}/usr/bin/httpd"
    chmod 777 "${fsdir}/usr/bin/httpd"
     
}
create_httpd_image()
{
    docker login -p zy930925 -u zhuyaliang
    sudo tar -C $fsdir -c . | sudo docker import - zhuyaliang/httpd_aarch64_os:latest
    docker push zhuyaliang/httpd_aarch64_os:latest 
}
create_base_image()
{
    docker login -p zy930925 -u zhuyaliang
    sudo tar -C $fsdir -c . | sudo docker import - zhuyaliang/new_aarch64_os:latest
    docker push zhuyaliang/new_aarch64_os:latest 
}
#main

env_check
down_pkg
unpacking_rpm
create_rootfs_env
create_image_repo
if [ "X$1" = "Xhttpd" ]; then
    create_httpd_env 
    create_httpd_image
else
    create_base_image
fi
