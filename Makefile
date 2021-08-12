PKGBUILDS-MAKEFILE := $(HOME)/pkgbuilds/Makefile

PKGS := ${dir ${wildcard ./*/PKGBUILD}}

CHROOT := $(HOME)/chroot

check-outdated:
	repoctl status -a

pull:
	git submodule update --remote

clean:
	git submodule foreach 'git clean -xffd'

$(PKGS):
	cd $@ && makechrootpkg -c -r /home/tetov/chroot -l $@ -- PACKAGER=$(PACKAGER)

sign-all-missing:
	find $(PKG_REPO) -iname "*.pkg.tar.zst" -exec sh -c "test -e {}.sig || gpg -v --detach-sign --no-armor {}" \;
	repoctl update

pacman.conf:
	curl -O https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/pacman/trunk/pacman.conf
	cat pacman.conf.addition >> pacman.conf

chroot: pacman.conf
	mkdir -p $(CHROOT)
	mkarchroot -C pacman.conf $(CHROOT)/root base-devel

.PHONY: $(PKGS) $(PKGS)/*.pkg.zst sign-all-missing chroot all pull clean sign-all-missing check-outdated chroot
