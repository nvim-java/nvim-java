local log = require('java.utils.log')
local notify = require('java-core.utils.notify')

local function get_checkers()
	local config = vim.g.nvim_java_config
	local checks = {}

	if config.verification.invalid_order then
		table.insert(checks, select(1, require('java.startup.exec-order-check')))
	end

	if config.verification.duplicate_setup_calls then
		table.insert(
			checks,
			select(1, require('java.startup.duplicate-setup-check'))
		)
	end

	table.insert(checks, select(1, require('java.startup.nvim-dep')))

	return checks
end

return function()
	local checkers = get_checkers()

	for _, check in ipairs(checkers) do
		local check_res = check.is_valid()

		if check_res.message then
			if not check_res.success then
				log.error(check_res.message)
				notify.error(check_res.message)
			else
				log.warn(check_res.message)
				notify.warn(check_res.message)
			end
		end

		if not check_res.continue then
			return false
		end
	end

	return true
end
