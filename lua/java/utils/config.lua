local M = {}

function M.get_property_from_conf(config, path, default)
	local node = config

	for key in string.gmatch(path, '([^.]+)') do
		if not node[key] then
			return default
		end

		node = node[key]
	end

	return node
end

return M
