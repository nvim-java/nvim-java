local mason_v2 = require('mason.version').MAJOR_VERSION == 2

local mason_sources

if mason_v2 then
	-- compiler will complain when Mason 1.x is used
	---@diagnostic disable-next-line: undefined-field
	mason_sources = require('mason-registry').sources
else
	mason_sources = require('mason-registry.sources')
end

local M = {}
if mason_v2 then
	M.JAVA_REG_ID = 'nvim-java/mason-registry'
else
	M.JAVA_REG_ID = 'github:nvim-java/mason-registry'
end

function M.is_valid()
	local iterator

	if mason_v2 then
		-- the compiler will complain when Mason 1.x is in use
		---@diagnostic disable-next-line: undefined-field
		iterator = mason_sources.iterate
	else
		-- the compiler will complain when Mason 2.x is in use
		---@diagnostic disable-next-line: undefined-field
		iterator = mason_sources.iter
	end

	for reg in iterator(mason_sources) do
		if reg.id == M.JAVA_REG_ID then
			return {
				success = true,
				continue = true,
			}
		end
	end

	return {
		success = false,
		continue = false,
		message = 'nvim-java mason registry is not added correctly!'
			.. '\nThis occurs when mason.nvim configured incorrectly'
			.. '\nPlease refer the link below to fix the issue'
			.. '\nhttps://github.com/nvim-java/nvim-java/wiki/Q-&-A#no_entry-cannot-find-package-xxxxx',
	}
end

return M
