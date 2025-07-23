local mason_source = require('mason-registry.sources')

local M = {
	JAVA_REG_ID = 'github:nvim-java/mason-registry',
}

function M.is_valid()
	local has_reg = false

	for reg in mason_source:iterate() do
		if reg.id == M.JAVA_REG_ID then
			has_reg = true
			goto continue
		end
	end

	::continue::

	if has_reg then
		return {
			success = true,
			continue = true,
		}
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
