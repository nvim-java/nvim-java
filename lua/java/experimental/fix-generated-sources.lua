local path_utils = require('java-core.utils.path')

local M = {}

local function set_exclusions(line, exclusions)
	local exclusion_value = table.concat(exclusions, '|')
	if line:match('excluding="[^"]+"') then
		return line:gsub('excluding="([^"]+)"', 'excluding="' .. exclusion_value .. '"', 1)
	end

	return line:gsub('<classpathentry ', '<classpathentry excluding="' .. exclusion_value .. '" ', 1)
end

local function get_relative_path(root, absolute_path)
	local prefix = root .. path_utils.path_separator
	if absolute_path:sub(1, #prefix) == prefix then
		return absolute_path:sub(#prefix + 1)
	end

	return absolute_path
end

local function has_classpath_entry(lines, entry_path)
	local pattern = 'path="' .. vim.pesc(entry_path) .. '"'
	for _, line in ipairs(lines) do
		if line:find(pattern) then
			return true
		end
	end

	return false
end

local function find_generated_sources_entry(lines)
	for index, line in ipairs(lines) do
		if line:find('path="target/generated%-sources"') then
			return index
		end
	end

	return nil
end

local function add_classpath_entry(lines, entry_path)
	local entry = {
		'\t<classpathentry kind="src" output="target/classes" path="' .. entry_path .. '">',
		'\t\t<attributes>',
		'\t\t\t<attribute name="optional" value="true"/>',
		'\t\t\t<attribute name="maven.pomderived" value="true"/>',
		'\t\t</attributes>',
		'\t</classpathentry>',
	}

	local output_index = #lines + 1
	for index, line in ipairs(lines) do
		if line:find('<classpathentry kind="output"') then
			output_index = index
			break
		end
	end

	for offset = #entry, 1, -1 do
		table.insert(lines, output_index, entry[offset])
	end

	return true
end

local function get_generated_source_roots(module_root)
	local generated_root = path_utils.join(module_root, 'target', 'generated-sources')
	if not vim.uv.fs_stat(generated_root) then
		return {}
	end

	local java_roots = vim.fs.find(function(name, generated_path)
		return name == 'java' and generated_path:find(vim.pesc(path_utils.join('target', 'generated-sources')), 1, false) ~= nil
	end, {
		path = generated_root,
		type = 'directory',
		limit = math.huge,
	})

	local source_roots = {}
	local seen_roots = {}
	for _, java_root in ipairs(java_roots) do
		local relative_to_generated_root = get_relative_path(generated_root, java_root)
		local segments = vim.split(relative_to_generated_root, path_utils.path_separator, { plain = true })
		local segment_count = #segments

		if segment_count >= 3 and segments[segment_count] == 'java' and segments[segment_count - 2] == 'src' then
			local source_root = get_relative_path(module_root, java_root)
			if not seen_roots[source_root] then
				seen_roots[source_root] = true
				table.insert(source_roots, source_root)
			end
		end
	end

	table.sort(source_roots)
	return source_roots
end

local function get_generated_source_exclusions(source_roots)
	local exclusions = { ['annotations/'] = true }
	local generated_root_prefix = path_utils.join('target', 'generated-sources') .. path_utils.path_separator

	for _, source_root in ipairs(source_roots) do
		if source_root:sub(1, #generated_root_prefix) == generated_root_prefix then
			local relative_to_generated_root = source_root:sub(#generated_root_prefix + 1)
			local first_segment = vim.split(relative_to_generated_root, path_utils.path_separator, { plain = true })[1]
			if first_segment then
				exclusions[first_segment .. '/'] = true
			end
		end
	end

	local ordered_exclusions = vim.tbl_keys(exclusions)
	table.sort(ordered_exclusions)
	return ordered_exclusions
end

local function patch_module_classpath(classpath_file)
	local module_root = vim.fs.dirname(classpath_file)
	local lines = vim.fn.readfile(classpath_file)
	local generated_sources_entry_index = find_generated_sources_entry(lines)
	if not generated_sources_entry_index then
		return false
	end

	local file_changed = false
	local source_roots = get_generated_source_roots(module_root)
	local line = lines[generated_sources_entry_index]
	local patched = set_exclusions(line, get_generated_source_exclusions(source_roots))

	if patched ~= line then
		lines[generated_sources_entry_index] = patched
		file_changed = true
	end

	for _, source_root in ipairs(source_roots) do
		if not has_classpath_entry(lines, source_root) then
			add_classpath_entry(lines, source_root)
			file_changed = true
		end
	end

	if file_changed then
		vim.fn.writefile(lines, classpath_file)
	end

	return file_changed
end

function M.patch(root)
	local changed = false
	for _, file in ipairs(vim.fs.find('.classpath', { path = root, type = 'file', limit = math.huge })) do
		if patch_module_classpath(file) then
			changed = true
		end
	end

	return changed
end

return M
