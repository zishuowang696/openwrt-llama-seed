.PHONY: build model qemu clean

build:
	./scripts/build-static.sh

model:
	./scripts/fetch-model.sh

qemu:
	./scripts/qemu-smoke.sh

clean:
	rm -rf .build dist .cache
