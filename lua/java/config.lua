---@class java.Config
---@field root_markers string[]
---@field java_test { enable: boolean }
---@field java_debug_adapter { enable: boolean }
---@field jdk { auto_install: boolean }
---@field notifications { dap: boolean }
local config = {
	--  list of file that exists in root of the project
	root_markers = {
		'settings.gradle',
		'settings.gradle.kts',
		'pom.xml',
		'build.gradle',
		'mvnw',
		'gradlew',
		'build.gradle',
		'build.gradle.kts',
		'.git',
	},

	-- load java test plugins
	java_test = {
		enable = true,
	},

	-- load java debugger plugins
	java_debug_adapter = {
		enable = true,
	},

	jdk = {
		-- install jdk using mason.nvim
		auto_install = true,
	},

	notifications = {
		-- enable 'Configuring DAP' & 'DAP configured' messages on start up
		dap = true,
	},
}

return config
