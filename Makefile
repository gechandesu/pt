PT_VERSION ?= 0.0.1

all: prod

dev:
	v -o pt src/

prod:
	v -prod -cc gcc -cflags -static -o pt src/ \
		-d pt_version=$(PT_VERSION) \
		-d pt_piddir=pt \
		-d pt_max_recursion_depth=10 \
		-d pt_default_config_file=~/.ptrc
