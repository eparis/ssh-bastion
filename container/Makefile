build:
	docker build . -t quay.io/${USER}/ssh

push: build
	docker push quay.io/${USER}/ssh

.PHONY: build push
