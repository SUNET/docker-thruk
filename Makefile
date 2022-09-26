VERSION := v$(shell date +%Y-%m-%d_%H_%M)
NAME=thruk

main: build tag push

release: build tag release_tag push

build:
	docker build --no-cache=true -t $(NAME):$(VERSION) -t  $(NAME):latest .

tag:
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):latest
release_tag:
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)
push:
	docker push --all-tags docker.sunet.se/$(NAME)
