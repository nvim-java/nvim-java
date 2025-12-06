local JDTLS_VERSION = '1.54.0'

local jdtls_version_map = {
	['1.43.0'] = {
		lombok = '1.18.40',
		java_test = '0.40.1',
		java_debug_adapter = '0.58.2',
		spring_boot_tools = '1.55.1',
		jdk = '17',
	},
	['1.54.0'] = {
		lombok = '1.18.42',
		java_test = '0.43.2',
		java_debug_adapter = '0.58.3',
		spring_boot_tools = '1.55.1',
		jdk = '17',
	},
}

local V = jdtls_version_map[JDTLS_VERSION]

---@class java.Config
---@field checks { nvim_version: boolean, nvim_jdtls_conflict: boolean }
---@field jdtls { version: string }
---@field lombok { enable: boolean, version: string }
---@field java_test { enable: boolean, version: string }
---@field java_debug_adapter { enable: boolean, version: string }
---@field spring_boot_tools { enable: boolean, version: string }
---@field jdk { auto_install: boolean, version: string }
---@field log java-core.Log2Config

---@class java.PartialConfig
---@field checks? { nvim_version?: boolean, nvim_jdtls_conflict?: boolean }
---@field jdtls? { version?: string }
---@field lombok? { enable?: boolean, version?: string }
---@field java_test? { enable?: boolean, version?: string }
---@field java_debug_adapter? { enable?: boolean, version?: string }
---@field spring_boot_tools? { enable?: boolean, version?: string }
---@field jdk? { auto_install?: boolean, version?: string }
---@field log? java-core.PartialLog2Config

---@type java.Config
local config = {
	checks = {
		nvim_version = true,
		nvim_jdtls_conflict = true,
	},

	jdtls = {
		version = JDTLS_VERSION,
	},

	lombok = {
		enable = true,
		version = V.lombok,
	},

	-- load java test plugins
	java_test = {
		enable = true,
		version = V.java_test,
	},

	-- load java debugger plugins
	java_debug_adapter = {
		enable = true,
		version = V.java_debug_adapter,
	},

	spring_boot_tools = {
		enable = true,
		version = V.spring_boot_tools,
	},

	jdk = {
		auto_install = true,
		version = V.jdk,
	},

	log = {
		use_console = true,
		use_file = true,
		level = 'info',
		log_file = vim.fn.stdpath('state') .. '/nvim-java.log',
		max_lines = 1000,
		show_location = false,
	},
}

return config
