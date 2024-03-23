---@class java.Config
---@field root_markers string[] list of file that exists in root of the project
---@field jdtls_plugins string[] what plugins to load
---@field java_test { enable: boolean }
---@field java_debug_adapter { enable: boolean }
---@field jdk { auto_install: boolean }

local config = {
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
	java_test = {
		enable = true,
	},
	java_debug_adapter = {
		enable = true,
	},
	jdk = {
		auto_install = true,
	},
	notifications = {
		dap = true,
	},
}

return config
