.PHONY: test prepare

prepare:
	@git submodule update --depth 1 --init

test: prepare
	@nvim \
			--headless \
			--noplugin \
			-u tests/minimal_vim.vim \
			-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_vim.vim' }"
