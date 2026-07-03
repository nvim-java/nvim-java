globals = {
	'vim.o',
	'vim.g',
	'vim.wo',
	'vim.bo',
	'vim.opt',
	'vim.lsp',
	'vim.ui',
}
read_globals = {
	'vim',
	'describe',
	'it',
	'assert',
}
ignore = {
	'212/self',
}
files['tests/specs/pkgm_resolve_spec.lua'] = {
	globals = {
		'vim.notify',
	},
}
max_line_length = false
