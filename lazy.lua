return {
	'nvim-java/nvim-java',
	dependencies = {
		'nvim-java/lua-async-await',
		'nvim-java/nvim-java-refactor',
		'nvim-java/nvim-java-core',
		'nvim-java/nvim-java-test',
		'nvim-java/nvim-java-dap',
		'MunifTanjim/nui.nvim',
		'neovim/nvim-lspconfig',
		'mfussenegger/nvim-dap',
		{
			'JavaHello/spring-boot.nvim',
			commit = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
		},
		{
			'mason-org/mason.nvim',
			-- opts = {
			-- registries = {
			-- 	'github:nvim-java/mason-registry',
			-- 	'github:mason-org/mason-registry',
			-- },
			-- },
		},
	},
}
