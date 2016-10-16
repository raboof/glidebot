all: image

.PHONY: image
image:
	docker build -t raboof/glidebot .

.PHONY: publish
publish:
	docker push raboof/glidebot
