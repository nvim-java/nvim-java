local jdtls = require('java.utils.jdtls2')
local get_error_handler = require('java.handlers.error')

local async = require('java-core.utils.async').sync

local JavaCoreJdtlsClient = require('java-core.ls.clients.jdtls-client')

local M = {}

---@class BufReadCmdCallbackArgs
---@field buf integer buffer number
---@field event string name of the event
---@field file string name of the file
---@field id integer event id?
---@field match string matched pattern in autocmd match

function M.setup()
	vim.api.nvim_create_autocmd('BufReadCmd', {
		pattern = 'jdt://*',
		---@param opts BufReadCmdCallbackArgs
		callback = function(opts)
			local done = false

			async(function()
					local client = jdtls()
					local buffer = opts.buf

					local text = JavaCoreJdtlsClient(client):java_decompile(opts.file)

					local lines = vim.split(text, '\n')

					vim.bo[buffer].modifiable = true

					vim.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

					vim.bo[buffer].swapfile = false
					vim.bo[buffer].filetype = 'java'
					vim.bo[buffer].modifiable = false

					if not vim.lsp.buf_is_attached(buffer, client.id) then
						vim.lsp.buf_attach_client(buffer, client.id)
					end

					done = true
				end)
				.catch(get_error_handler('decompilation failed for ' .. opts.file))
				.run()

			vim.wait(10000, function()
				return done
			end)
		end,
	})
end

return M
