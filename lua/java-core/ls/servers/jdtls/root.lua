local M = {}

local root_markers1 = {
	-- Multi-module projects
	'mvnw', -- Maven
	'gradlew', -- Gradle
	'settings.gradle', -- Gradle
	'settings.gradle.kts', -- Gradle
	-- Use git directory as last resort for multi-module maven projects
	-- In multi-module maven projects it is not really possible to determine what is the parent directory
	-- and what is submodule directory. And jdtls does not break if the parent directory is at higher level than
	-- actual parent pom.xml so propagating all the way to root git directory is fine
	'.git',
}

local root_markers2 = {
	-- Single-module projects
	'build.xml', -- Ant
	'pom.xml', -- Maven
	'build.gradle', -- Gradle
	'build.gradle.kts', -- Gradle
}

function M.get_root_markers()
	return vim.fn.has('nvim-0.11.3') == 1 and { root_markers1, root_markers2 }
		or vim.list_extend(root_markers1, root_markers2)
end

return M
