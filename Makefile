.PHONY: test prepare

prepare:
	@if [ ! -d "./vendor/plenary.nvim" ]; then git clone https://github.com/nvim-lua/plenary.nvim vendor/plenary.nvim; fi

test: prepare
	@nvim \
		--headless \
		--noplugin \
		-u tests/minimal_vim.vim \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_vim.vim' }"
