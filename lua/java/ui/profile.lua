local Layout = require('nui.layout')
local Menu = require('nui.menu')
local Popup = require('nui.popup')
local notify = require('java-core.utils.notify')
local profile_config = require('java.api.profile_config')
local class = require('java-core.utils.class')
local dap_api = require('java.api.dap')

local new_profile = 'New Profile'

--- @param up_win number
--- @param down_win number
local function map_keys_for_profile_editor(popup, up_win, down_win)
	local function go_up()
		vim.api.nvim_set_current_win(up_win)
	end

	local function go_down()
		vim.api.nvim_set_current_win(down_win)
	end

	popup:map('n', '<Tab>', go_down)
	popup:map('n', 'k', go_up)
	popup:map('n', 'j', go_down)
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
local function save_profile(popups, target_profile)
	local vm_args = get_popup_value(popups.vm_args)
	local prog_args = get_popup_value(popups.prog_args)
	local name = get_popup_value(popups.name)
	local profile = profile_config.Profile(vm_args, prog_args, name)

	if profile.name == nil or profile.name == '' then
		notify.warn('Profile name is required')
		return false
	end

	if target_profile then
		if is_contains_active_postfix(target_profile) then
			target_profile = clear_active_postfix(target_profile)
		end
	else
		if profile_config.get_profile_by_name(profile.name) then
			notify.warn('Profile name already exists')
			return false
		end
	end
	profile_config.add_or_update_profile(profile, target_profile)
	dap_api.config_dap()
	return true
end

--- @class ProfileUI
--- @field win_options table
--- @field style string
--- @field focus_item NuiTree.Node
local ProfileUI = class()

function ProfileUI:_init()
	self.win_options = {
		winhighlight = 'Normal:Normal,FloatBorder:Normal',
	}
	self.style = 'single'
	self.focus_item = nil
end

---@return NuiTree.Node[]
function ProfileUI.get_tree_node_list_for_menu()
	local menu_nodes = {}
	local profiles = profile_config.get_all_profiles()
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
	local lines = self.get_tree_node_list_for_menu()
	return Menu({
		relative = 'editor',
		position = '50%',
		size = {
			width = 25,
			height = 5,
		},
		border = {
			style = self.style,
			text = {
				top = '[Profiles]',
				top_align = 'center',
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
		on_change = function(item)
			self.focus_item = item
		end,
		on_submit = function(item)
			if item.text == new_profile then
				self:_open_profile_editor()
			else
				local profile_name = clear_active_postfix(item.text)
				self:_open_profile_editor(profile_name)
			end
		end,
	})
end

function ProfileUI:_get_and_fill_popup(title, key, target_profile, enter)
	local popup = Popup({
		border = {
			style = self.style,
			text = { top = '[' .. title .. ']', top_align = 'center' },
		},
		enter = enter or false,
		win_options = self.win_options,
	})
	-- fill the popup with the config value
	-- if target_profile is nil, it's a new profile
	if target_profile then
		vim.api.nvim_buf_set_lines(
			popup.bufnr,
			0,
			-1,
			false,
			{ profile_config.get_profile_by_name(target_profile)[key] }
		)
	end
	return popup
end

function ProfileUI:_open_profile_editor(target_profile)
	local popups = {
		name = self:_get_and_fill_popup('Name', 'name', target_profile, true),
		vm_args = self:_get_and_fill_popup(
			'VM arguments',
			'vm_args',
			target_profile
		),
		prog_args = self:_get_and_fill_popup(
			'Program arguments',
			'prog_args',
			target_profile
		),
	}

	local layout = Layout(
		{
			relative = 'editor',
			position = '50%',
			size = { height = 15, width = 60 },
		},

		Layout.Box({
			Layout.Box(popups.name, { grow = 0.2 }),
			Layout.Box(popups.vm_args, { grow = 0.4 }),
			Layout.Box(popups.prog_args, { grow = 0.4 }),
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
			if save_profile(popups, target_profile) then
				layout:unmount()
			end
		end)
	end

	map_keys_for_profile_editor(
		popups.name, -- popup (first)
		popups.prog_args.winid, -- up_win
		popups.vm_args.winid -- down_win
	)

	map_keys_for_profile_editor(
		popups.vm_args, -- popup (second)
		popups.name.winid, -- up_win
		popups.prog_args.winid -- down_win
	)
	map_keys_for_profile_editor(
		popups.prog_args, -- popup (third)
		popups.vm_args.winid, -- up_win
		popups.name.winid -- down_win
	)
end

--- @return boolean
function ProfileUI:_is_selected_profile_modifiable()
	if
		self.focus_item == nil
		or self.focus_item.text == nil
		or self.focus_item.text == new_profile
	then
		return false
	end
	return true
end

function ProfileUI:_set_active_profile()
	if not self:_is_selected_profile_modifiable() then
		notify.error('Failed to set profile as active')
		return
	end

	if is_contains_active_postfix(self.focus_item.text) then
		return
	end

	profile_config.set_active_profile(self.focus_item.text)
	dap_api.config_dap()
	self.menu:unmount()
	self:openMenu()
end

function ProfileUI:_delete_profile()
	if not self:_is_selected_profile_modifiable() then
		notify.error('Failed to delete profile')
		return
	end
	if is_contains_active_postfix(self.focus_item.text) then
		notify.warn('Cannot delete active profile')
		return
	end

	profile_config.delete_profile(self.focus_item.text)
	self.menu:unmount()
	self:openMenu()
end

function ProfileUI:openMenu()
	self.menu = self:get_menu()
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
		self:_set_active_profile()
	end, { noremap = true, nowait = true })
	-- delete
	self.menu:map('n', 'd', function()
		self:_delete_profile()
	end, { noremap = true, nowait = true })
end

local M = {}

--- @type ProfileUI
M.ProfileUI = ProfileUI
function M.ui()
	M.profile_ui = ProfileUI()
	return M.profile_ui:openMenu()
end

return M
