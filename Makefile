DOCKER_USER:=bbqlinux
DOCKER_ORGANIZATION=bbqlinux
DOCKER_IMAGE:=base

rootfs:
	$(eval TMPDIR := $(shell mktemp -d))
	env -i wget https://raw.githubusercontent.com/bbqlinux/bbqlinux-config/master/src/etc/pacman.x86_64.conf.bbqnew -O rootfs/etc/pacman.conf
	env -i wget https://raw.githubusercontent.com/bbqlinux/bbqlinux-config/master/src/etc/pacman.bbqlinux.conf -O rootfs/etc/pacman.bbqlinux.conf
	env -i wget http://mirrorlist.bbqlinux.org/ -O rootfs/etc/pacman.d/bbqlinux-mirrorlist
	env -i pacstrap -C rootfs/etc/pacman.conf -c -d -G -M $(TMPDIR) $(shell cat packages)
	cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* $(TMPDIR)/
	arch-chroot $(TMPDIR) locale-gen
	arch-chroot $(TMPDIR) pacman-key --init
	arch-chroot $(TMPDIR) pacman-key --populate archlinux
	arch-chroot $(TMPDIR) pacman-key --populate bbqlinux
	tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(TMPDIR) -c . -f bbqlinux.tar
	rm -rf $(TMPDIR)

docker-image: rootfs
	docker build -t $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) .

docker-image-test: docker-image
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm docker && docker -v"
	# Ensure that the image does not include a private key
	! docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) pacman-key --lsign-key pierre@archlinux.de
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/id -u http"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm grep && locale | grep -q UTF-8"

ci-test:
	docker run --rm --privileged --tmpfs=/tmp:exec --tmpfs=/run/shm -v /run/docker.sock:/run/docker.sock \
		-v $(PWD):/app -w /app $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) \
		sh -c 'pacman -Syu --noconfirm make devtools docker && make docker-image-test'

docker-push:
	docker login -u $(DOCKER_USER)
	docker push $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE)

.PHONY: rootfs docker-image docker-image-test ci-test docker-push
