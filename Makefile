# also update debian/changelog
KVMVER=2.9.0
KVMTAG=$(KVMVER)-rc2
KVMPKGREL=1~rc2+2

KVMPACKAGE=pve-qemu-kvm
KVMDIR=qemu-kvm
KVMSRC=${KVMDIR}-src.tar.gz

ARCH ?= $(shell dpkg-architecture -qDEB_HOST_ARCH)
GITVERSION:=$(shell git rev-parse master)

DEB=${KVMPACKAGE}_${KVMVER}-${KVMPKGREL}_${ARCH}.deb
DEB_DBG=${KVMPACKAGE}-dbg_${KVMVER}-${KVMPKGREL}_${ARCH}.deb
DEBS=$(DEB) $(DEB_DBG)


all: $(DEBS)

.PHONY: download
download:
	rm -rf ${KVMDIR} ${KVMSRC}
	git clone --depth=1 git://git.qemu-project.org/qemu.git -b v${KVMTAG} ${KVMDIR}
	tar czf ${KVMSRC} --exclude CVS --exclude .git --exclude .svn ${KVMDIR}

.PHONY: deb kvm
deb kvm: $(DEBS)
$(DEB_DBG): $(DEB)
$(DEB): $(KVMSRC)
	rm -f *.deb
	rm -rf ${KVMDIR}
	tar xf ${KVMSRC} 
	cp -a debian ${KVMDIR}/debian
	echo "git clone git://git.proxmox.com/git/pve-qemu-kvm.git\\ngit checkout ${GITVERSION}" > ${KVMDIR}/debian/SOURCE
	# set package version
	sed -i 's/^pkgversion="".*/pkgversion="${KVMPACKAGE}_${KVMVER}-${KVMPKGREL}"/' ${KVMDIR}/configure
	cd ${KVMDIR}; dpkg-buildpackage -b -rfakeroot -us -uc
	lintian ${DEBS} || true

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload --product pve --dist stretch

.PHONY: distclean
distclean: clean


.PHONY: clean
clean:
	rm -rf *.changes *.buildinfo ${KVMDIR} ${KVMPACKAGE}_* ${DEBS}

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
