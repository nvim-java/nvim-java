local event = require('nui.utils.autocmd').event
local notify = require('java-core.utils.notify')
local profile_config = require('java.api.profile_config')
local class = require('java-core.utils.class')
local dap_api = require('java-dap')
local env_utils = require('java.utils.env')
local lsp_utils = require('java-core.utils.lsp')
local ui = require('java.ui.utils')

local Layout = require('nui.layout')
local Menu = require('nui.menu')
local Popup = require('nui.popup')
local DapSetup = require('java-dap.setup')

local new_profile = 'New Profile'

---@param ordered_popups Popup[]
local function map_keys_for_profile_editor(ordered_popups)
	for index, popup in ipairs(ordered_popups) do
		local up_index = index == 1 and #ordered_popups or index - 1
		local down_index = index == #ordered_popups and 1 or index + 1

		popup:map('n', '<Tab>', function()
			vim.api.nvim_set_current_win(ordered_popups[down_index].winid)
		end)
		popup:map('n', 'k', function()
			vim.api.nvim_set_current_win(ordered_popups[up_index].winid)
		end)
		popup:map('n', 'j', function()
			vim.api.nvim_set_current_win(ordered_popups[down_index].winid)
		end)
	end
end

--- @param popup Popup
--- @return string
local function get_popup_value(popup)
	local ok, value = pcall(vim.api.nvim_buf_get_lines, popup.bufnr, 0, -1, false)
	if ok then
		return value[1]
	end
	notify.error('Failed to get popup value for ' .. popup.name)
end

---@param popup Popup
---@return string[]
local function get_popup_lines(popup)
	local ok, value = pcall(vim.api.nvim_buf_get_lines, popup.bufnr, 0, -1, false)
	if ok then
		return value
	end
	notify.error('Failed to get popup value for ' .. popup.name)
	return {}
end

--- @param name string
--- @return boolean
local function is_contains_active_postfix(name)
	return name:match('^(.*)(active)')
end

--- @param name string
--- @return string
local function clear_active_postfix(name)
	local val, _ = name:gsub(' %(.+%)', '')
	return val
end

--- @param popups table<string, Popup>
--- @param target_profile string
local function save_profile(popups, target_profile, main_class)
	local vm_args = get_popup_value(popups.vm_args)
	local prog_args = get_popup_value(popups.prog_args)
	local env_file = vim.trim(get_popup_value(popups.env_file) or '')
	local env, err = env_utils.parse_lines(get_popup_lines(popups.env))
	local name = get_popup_value(popups.name)

	if err then
		notify.warn('Invalid environment entries: ' .. err)
		return false
	end

	if env_file ~= '' then
		local _, env_file_err = env_utils.read_file(
			env_file,
			profile_config.current_project_path
		)
		if env_file_err then
			notify.warn(env_file_err)
			return false
		end
	end

	local profile = profile_config.Profile(
		vm_args,
		prog_args,
		name,
		nil,
		env,
		env_file ~= '' and env_file or nil
	)

	if profile.name == nil or profile.name == '' then
		notify.warn('Profile name is required')
		return false
	end

	if target_profile then
		if is_contains_active_postfix(target_profile) then
			target_profile = clear_active_postfix(target_profile)
		end
	else
		if profile_config.get_profile(profile.name, main_class) then
			notify.warn('Profile name already exists')
			return false
		end
	end
	profile_config.add_or_update_profile(profile, target_profile, main_class)
	dap_api.config_dap()
	return true
end

--- @class ProfileUI
--- @field win_options table
--- @field style string
--- @field focus_item NuiTree.Node
--- @field main_class string
local ProfileUI = class()

function ProfileUI:_init(main_class)
	self.main_class = main_class
	self.win_options = {
		winhighlight = 'Normal:Normal,FloatBorder:Normal',
	}
	self.style = 'single'
	self.keymap_style = 'rounded'
	self.focus_item = nil
end

---@return NuiTree.Node[]
function ProfileUI:get_tree_node_list_for_menu()
	local menu_nodes = {}
	local profiles = profile_config.get_all_profiles(self.main_class)
	local count = 1
	for key, profile in pairs(profiles) do
		if profile.is_active then
			key = key .. ' (active)'
			menu_nodes[1] = Menu.item(key)
		else
			count = count + 1
			menu_nodes[count] = Menu.item(key)
		end
	end
	table.insert(menu_nodes, Menu.separator())
	table.insert(menu_nodes, Menu.item(new_profile))
	return menu_nodes
end

--- @return Menu
function ProfileUI:get_menu()
	local lines = self:get_tree_node_list_for_menu()
	return Menu({
		relative = 'editor',
		position = '50%',
		size = {
			width = 40,
			height = 8,
		},
		border = {
			style = self.style,
			text = {
				top = '[Profiles]',
				top_align = 'center',
				bottom = '[a]ctivate [d]elete [b]ack [q]uit',
				bottom_align = 'center',
			},
		},
		win_options = self.win_options,
	}, {
		lines = lines,
		max_width = 20,
		keymap = {
			focus_next = { 'j', '<Down>', '<Tab>' },
			focus_prev = { 'k', '<Up>', '<S-Tab>' },
			close = { '<Esc>', '<C-c>' },
			submit = { '<CR>', '<Space>' },
		},
		on_submit = function(item)
			if item.text == new_profile then
				self:open_profile_editor()
			else
				local profile_name = clear_active_postfix(item.text)
				self:open_profile_editor(profile_name)
			end
		end,
	})
end

---@private
--- @param title string
--- @param key string
--- @param target_profile string
--- @param enter boolean|nil
--- @param keymaps boolean|nil
function ProfileUI:get_and_fill_popup(title, key, target_profile, enter, keymaps)
	local style = self.style
	local text = {
		top = '[' .. title .. ']',
		top_align = 'center',
	}

	if keymaps then
		text.bottom = '[s]ave [b]ack [q]uit'
		text.bottom_align = 'center'
	end

	local popup = Popup({
		border = {
			style = style,
			text = text,
		},
		enter = enter or false,
		win_options = self.win_options,
	})

	-- fill the popup with the config value
	-- if target_profile is nil, it's a new profile
	if target_profile then
		local value = profile_config.get_profile(target_profile, self.main_class)[key]
		if key == 'env' then
			value = env_utils.stringify(value)
		end
		if value == nil or value == '' then
			value = ''
		end

		vim.api.nvim_buf_set_lines(
			popup.bufnr,
			0,
			-1,
			false,
			vim.split(value, '\n', { plain = true })
		)
	end
	return popup
end

---@private
function ProfileUI:open_profile_editor(target_profile)
	local popups = {
		name = self:get_and_fill_popup('Name', 'name', target_profile, true, false),
		vm_args = self:get_and_fill_popup('VM arguments', 'vm_args', target_profile, false, false),
		prog_args = self:get_and_fill_popup('Program arguments', 'prog_args', target_profile, false, false),
		env = self:get_and_fill_popup('Environment', 'env', target_profile, false, false),
		env_file = self:get_and_fill_popup('Environment file', 'env_file', target_profile, false, true),
	}
	local ordered_popups = {
		popups.name,
		popups.vm_args,
		popups.prog_args,
		popups.env,
		popups.env_file,
	}

	local layout = Layout(
		{
			relative = 'editor',
			position = '50%',
			size = { height = 22, width = 60 },
		},

		Layout.Box({
			Layout.Box(popups.name, { grow = 0.15 }),
			Layout.Box(popups.vm_args, { grow = 0.2 }),
			Layout.Box(popups.prog_args, { grow = 0.2 }),
			Layout.Box(popups.env, { grow = 0.3 }),
			Layout.Box(popups.env_file, { grow = 0.15 }),
		}, { dir = 'col' })
	)

	layout:mount()
	for _, popup in pairs(popups) do
		-- go back
		popup:map('n', 'b', function()
			layout:unmount()
			self:openMenu()
		end)
		-- quit
		popup:map('n', 'q', function()
			layout:unmount()
		end)
		-- save
		popup:map('n', 's', function()
			if save_profile(popups, target_profile, self.main_class) then
				layout:unmount()
			end
		end)
	end

	map_keys_for_profile_editor(ordered_popups)
end

---@private
--- @return boolean
function ProfileUI:is_selected_profile_modifiable()
	if self.focus_item == nil or self.focus_item.text == nil or self.focus_item.text == new_profile then
		return false
	end
	return true
end

---@private
function ProfileUI:set_active_profile()
	if not self:is_selected_profile_modifiable() then
		notify.error('Failed to set profile as active')
		return
	end

	if is_contains_active_postfix(self.focus_item.text) then
		return
	end

	profile_config.set_active_profile(self.focus_item.text, self.main_class)
	dap_api.config_dap()
	self.menu:unmount()
	self:openMenu()
end

---@private
function ProfileUI:delete_profile()
	if not self:is_selected_profile_modifiable() then
		notify.error('Failed to delete profile')
		return
	end
	if is_contains_active_postfix(self.focus_item.text) then
		notify.warn('Cannot delete active profile')
		return
	end

	profile_config.delete_profile(self.focus_item.text, self.main_class)
	self.menu:unmount()
	self:openMenu()
end

function ProfileUI:openMenu()
	self.menu = self:get_menu()

	self.menu:on(event.CursorMoved, function()
		self.focus_item = self.menu.tree:get_node()
	end)

	self.menu:mount()
	-- quit
	self.menu:map('n', 'q', function()
		self.menu:unmount()
	end, { noremap = true, nowait = true })
	-- back
	self.menu:map('n', 'b', function()
		self.menu:unmount()
	end, { noremap = true, nowait = true })
	self.menu:map('n', 'a', function()
		self:set_active_profile()
	end, { noremap = true, nowait = true })
	-- delete
	self.menu:map('n', 'd', function()
		self:delete_profile()
	end, { noremap = true, nowait = true })
end

local M = {}

local runner = require('async.runner')
local get_error_handler = require('java-core.utils.error_handler')

--- @type ProfileUI
M.ProfileUI = ProfileUI

function M.ui()
	return runner(function()
			local configs = DapSetup(lsp_utils.get_jdtls()):get_dap_config()

			if not configs or #configs == 0 then
				notify.error('No classes with main methods are found')
				return
			end

			local selected_config = ui.select('Select the main class (module -> mainClass)', configs, function(config)
				return config.name
			end)

			if not selected_config then
				return
			end

			M.profile_ui = ProfileUI(selected_config.name)
			return M.profile_ui:openMenu()
		end)
		.catch(get_error_handler('failed to run app'))
		.run()
end

return M
