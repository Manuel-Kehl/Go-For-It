#!/bin/sh

archs="fedora-28-x86_64"

version=$(cat CMakeLists.txt | grep "set (VERSION " | cut -d '"' -f 2)

cd ..
tar czf go-for-it-${version}.tar.gz Go-For-It
mv go-for-it-${version}.tar.gz Go-For-It/rpm/
cd Go-For-It

for arch in ${archs}
do
	mkdir -p rpm/pkgs/${arch}
	rm -rf /tmp/go-for-it
	mkdir -p /tmp/go-for-it/${arch}/srpm
	mkdir -p /tmp/go-for-it/${arch}/rpm
	mock -r ${arch} --resultdir /tmp/go-for-it/${arch}/srpm --buildsrpm --spec rpm/go-for-it.spec --sources rpm/ --define "version ${version}"
	mock -r ${arch} --resultdir /tmp/go-for-it/${arch}/rpm --rebuild /tmp/go-for-it/${arch}/srpm/go-for-it-${version}*src.rpm --define "version ${version}"
	cp /tmp/go-for-it/${arch}/rpm/*.rpm rpm/pkgs/${arch}/
done
