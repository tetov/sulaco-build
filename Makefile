PACKAGER="Anton Tetov <anton@tetov.se>"
CHROOT=$$HOME/chroot

PKG-REPO=/srv/http/pkg-repo

PKGS := ${subst /,,${dir ${wildcard */PKGBUILD}}}

$(PKGS):
	cd $@ && makechrootpkg -c -r /home/tetov/chroot -l $@ -- PACKAGER=$(PACKAGER)

add-%:
	auracle buildorder $* || ( echo "Package or deps not found" && false )
	git submodule add https://aur.archlinux.org/$*
	auracle buildorder $* | grep AUR | awk '{print $$(NF-1)}' | xargs -I %% git submodule add https://aur.archlinux.org/%%
	git commit -m "added $* and deps"

check-outdated:
	repoctl status -a

chroot: pacman.conf
	mkdir -p $(CHROOT)
	mkarchroot -C pacman.conf $(CHROOT)/root base-devel

pacman.conf:
	curl -O https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/pacman/trunk/pacman.conf
	cat pacman.conf.addition >> pacman.conf

pull:
	git submodule update --remote --merge
	git commit -m "updated submodules" .

sign-all-and-update:
	find $(PKG-REPO) -iname "*.pkg.tar.zst" \
		-exec sh -c "test -e {}.sig || gpg -v --detach-sign --no-armor {}" \;
	repoctl update

all:
clean:
	git submodule foreach 'git clean -xffd'
test:

.PHONY: $(PKGS) sign-all check-outdated clean chroot pacman.conf pull sign-all-and-update all clean test
