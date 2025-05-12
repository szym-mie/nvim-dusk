MNT ?= $(CURDIR)/dusk:/home/dev/.config/nvim
IMG ?= nvim-dusk-dev
BDL ?= buildlog.txt

.PHONY: all
all: run

$(BDL): Dockerfile
	docker build -t $(IMG) .
	docker history $(IMG) > $@

.PHONY: build
build: $(BDL)

.PHONY: run
run: build
	docker run -it --rm -v $(MNT) $(IMG)

.PHONY: clean
clean:
	docker rmi $(IMG)