PACKAGER="Anton Tetov <anton@tetov.se>"
CHROOT=$$HOME/chroot

PKG-REPO=/srv/http/pkg-repo

PKGS := ${subst /,,${dir ${wildcard */PKGBUILD}}}

_pkg_files := ${wildcard $(PKG-REPO)/*.pkg.tar.zst}
SIG-FILES := ${addsuffix .sig,$(_pkg_files)}

$(PKGS):
	cd $@ && makechrootpkg -c -r /home/tetov/chroot -l $@ -- PACKAGER=$(PACKAGER)

%.sig: %
	gpg -v --detach-sign --no-armor $@

check-outdated:
	repoctl status -a

clean:
	git submodule foreach 'git clean -xffd'

chroot: pacman.conf
	mkdir -p $(CHROOT)
	mkarchroot -C pacman.conf $(CHROOT)/root base-devel

pacman.conf:
	curl -O https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/pacman/trunk/pacman.conf
	cat pacman.conf.addition >> pacman.conf

pull:
	git submodule update --remote


sign-all-and-update:
	find $(PKG-REPO) -iname "*.pkg.tar.zst" \
		-exec sh -c "test -e {}.sig || gpg -v --detach-sign --no-armor {}" \;
	repoctl update

.PHONY: $(PKGS) sign-all check-outdated clean chroot pacman.conf pull sign-all-and-update
