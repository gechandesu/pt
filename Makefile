all: prod

dev:
	v -o pt src/

prod:
	v -prod -cc gcc -cflags '-static -s' -o pt src/ \
		-d pt_version=$$(git describe --tags) \
		-d pt_piddir=pt \
		-d pt_max_recursion_depth=10 \
		-d pt_default_config_file=~/.ptrc

install:
	install -Dm0755 pt $$HOME/.local/bin/pt
	install -Dm0644 completion.bash $${XDG_DATA_HOME:-$$HOME/.local/share}/bash-completion/completions/pt
