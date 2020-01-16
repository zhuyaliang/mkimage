#!/bin/bash
rm -rf *.list
list="microdnf bash vim"
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
echo rpm >> ./tmp.list
echo openEuler-gpg-keys >> ./tmp.list
echo openEuler-release >> ./tmp.list
echo ncurses >> ./tmp.list 
echo vim-enhanced >> ./tmp.list
echo bash >> ./tmp.list
echo coreutils >> ./tmp.list
cat ./tmp.list | sort -k2n | uniq > ./pkg.list
rm -rf ./tmp.list
