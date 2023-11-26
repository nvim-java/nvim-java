local lspconfig = require('lspconfig')

local log = require('java.utils.log')
local jdtls = require('java.utils.jdtls')
local get_error_handler = require('java.handlers.error')

local server = require('java-core.ls.servers.jdtls')
local async = require('java-core.utils.async').sync

local JavaCoreJdtlsClient = require('java-core.ls.clients.jdtls-client')

local M = {}

function M.wrap_lspconfig_setup()
	log.info('wrap lspconfig.java.setup function to inject a custom java config')
	---@type fun(config: LspSetupConfig)
	local org_setup = lspconfig.jdtls.setup

	lspconfig.jdtls.setup = function(user_config)
		local config = server.get_config({
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
			jdtls_plugins = { 'java-test', 'java-debug-adapter' },
		})

		config = vim.tbl_deep_extend('force', user_config, config)

		org_setup(config)
	end
end

---@class BufReadCmdCallbackArgs
---@field buf integer buffer number
---@field event string name of the event
---@field file string name of the file
---@field id integer event id?
---@field match string matched pattern in autocmd match

function M.register_class_file_decomplier()
	vim.api.nvim_create_autocmd('BufReadCmd', {
		pattern = 'jdt://*',
		---@param opts BufReadCmdCallbackArgs
		callback = function(opts)
			local done = false

			async(function()
					local client_obj = jdtls()
					local buffer = opts.buf

					local text = JavaCoreJdtlsClient:new(client_obj)
						:java_decompile(opts.file)

					local lines = vim.split(text, '\n')
					vim.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

					vim.bo[buffer].swapfile = false
					vim.bo[buffer].filetype = 'java'
					vim.bo[buffer].modifiable = false

					if not vim.lsp.buf_is_attached(buffer, client_obj.client.id) then
						vim.lsp.buf_attach_client(buffer, client_obj.client.id)
					end

					done = true
				end)
				.catch(get_error_handler('decompilation failed for ' .. opts.file))
				.run()

			vim.wait(3000, function()
				return done
			end)
		end,
	})
end

return M
