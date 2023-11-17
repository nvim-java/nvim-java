local log = require('java-core.utils.log')
local lspconfig = require('lspconfig')
local server = require('java-core.ls.servers.jdtls')
local jdtls = require('java.jdtls')
local get_error_handler = require('java.handlers.error')

local JavaCoreJdtlsClient = require('java-core.ls.clients.jdtls-client')

local M = {}

function M.wrap_lspconfig_setup()
	log.info('wrap lspconfig.java.setup function to inject a custom java config')
	---@type fun(config: LSPSetupConfig)
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
			---@type boolean
			local done = false
			local client_obj = jdtls()
			local buffer = opts.buf

			local function handle_file_content(text)
				local lines = vim.split(text, '\n')
				vim.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

				vim.bo[buffer].swapfile = false
				vim.bo[buffer].filetype = 'java'
				vim.bo[buffer].modifiable = false

				if not vim.lsp.buf_is_attached(buffer, client_obj.client.id) then
					vim.lsp.buf_attach_client(buffer, client_obj.client.id)
				end

				done = true
			end

			JavaCoreJdtlsClient:new(client_obj)
				:java_decompile(opts.file)
				:thenCall(handle_file_content)
				:catch(
					get_error_handler('failed to decompile the class at  %s', opts.file)
				)

			vim.wait(10000, function()
				return done
			end)
		end,
	})
end

return M
