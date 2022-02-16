.PHONY: test prepare

prepare:
	@git clone https://github.com/nvim-lua/plenary.nvim vendor/plenary.nvim

test: prepare
	@nvim \
		--headless \
		--noplugin \
		-u tests/minimal_vim.vim \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_vim.vim' }"
