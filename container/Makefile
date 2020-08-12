build:
	podman build -t quay.io/${USER}/ssh .

push: build
	podman push quay.io/${USER}/ssh

.PHONY: build push
