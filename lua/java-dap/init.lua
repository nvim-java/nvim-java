local M = {}

function M.setup()
	local event = require('java-core.utils.event')
	local project_config = require('java.api.profile_config')
	local err = require('java-core.utils.errors')

	local has_dap = pcall(require, 'dap')

	if not has_dap then
		err.throw([[
			Please install https://github.com/mfussenegger/nvim-dap to enable debugging
			or disable the java_debug_adapter.enable option in your config
		]])
	end

	event.on_jdtls_attach({
		callback = function()
			project_config.setup()
			M.config_dap()
		end,
	})
end

---Configure dap
function M.config_dap()
	local get_error_handler = require('java-core.utils.error_handler')
	local notify = require('java-core.utils.notify')
	local runner = require('async.runner')

	return runner(function()
			local lsp_utils = require('java-core.utils.lsp')
			local nvim_dap = require('dap')
			local profile_config = require('java.api.profile_config')
			local env_utils = require('java.utils.env')
			local DapSetup = require('java-dap.setup')

			local client = lsp_utils.get_jdtls()
			local dap = DapSetup(client)

			----------------------------------------------------------------------
			--                             adapter                              --
			----------------------------------------------------------------------
			nvim_dap.adapters.java = function(callback)
				runner(function()
					local adapter = dap:get_dap_adapter()
					callback(adapter --[[@as dap.Adapter]])
				end).run()
			end

			----------------------------------------------------------------------
			--                              config                              --
			----------------------------------------------------------------------

			local dap_config = dap:get_dap_config()
			local applied_dap_config = {}
			local preserved_dap_config = {}
			for _, config in ipairs(nvim_dap.configurations.java or {}) do
				if not config._nvim_java_managed then
					table.insert(preserved_dap_config, config)
				end
			end

			for _, config in ipairs(dap_config) do
				local is_valid = true
				local profile = profile_config.get_active_profile(config.name)
				if profile then
					config.vmArgs = profile.vm_args
					config.args = profile.prog_args

					local env, err = env_utils.load_profile_env(
						profile,
						profile_config.current_project_path
					)
					if err then
						notify.error(err)
						is_valid = false
					else
						config.env = env
						config.envFile = profile.env_file
					end
				end

				if is_valid then
					config._nvim_java_managed = true
					table.insert(applied_dap_config, config)
				end
			end

			if nvim_dap.session then
				nvim_dap.terminate()
			end

			nvim_dap.configurations.java = preserved_dap_config
			vim.list_extend(nvim_dap.configurations.java, applied_dap_config)
		end)
		.catch(get_error_handler('dap configuration failed'))
		.run()
end

return M
