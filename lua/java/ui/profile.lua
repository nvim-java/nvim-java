local event = require('nui.utils.autocmd').event
local Layout = require('nui.layout')
local Menu = require('nui.menu')
local Popup = require('nui.popup')
local notify = require('java-core.utils.notify')
local profile_config = require('java.api.profile_config')
local class = require('java-core.utils.class')
local dap_api = require('java.api.dap')
local log = require('java.utils.log')
local DapSetup = require('java-dap.api.setup')
local jdtls = require('java.utils.jdtls')
local ui = require('java.utils.ui')

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
local function save_profile(popups, target_profile, main_class)
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
				self:_open_profile_editor()
			else
				local profile_name = clear_active_postfix(item.text)
				self:_open_profile_editor(profile_name)
			end
		end,
	})
end

--- @param title string
--- @param key string
--- @param target_profile string
--- @param enter boolean|nil
--- @param keymaps boolean|nil
function ProfileUI:_get_and_fill_popup(
	title,
	key,
	target_profile,
	enter,
	keymaps
)
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

	log.error(vim.inspect(popup.border))
	-- fill the popup with the config value
	-- if target_profile is nil, it's a new profile
	if target_profile then
		vim.api.nvim_buf_set_lines(
			popup.bufnr,
			0,
			-1,
			false,
			{ profile_config.get_profile(target_profile, self.main_class)[key] }
		)
	end
	return popup
end

function ProfileUI:_open_profile_editor(target_profile)
	local popups = {
		name = self:_get_and_fill_popup(
			'Name',
			'name',
			target_profile,
			true,
			false
		),
		vm_args = self:_get_and_fill_popup(
			'VM arguments',
			'vm_args',
			target_profile,
			false,
			false
		),
		prog_args = self:_get_and_fill_popup(
			'Program arguments',
			'prog_args',
			target_profile,
			false,
			true
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
			if save_profile(popups, target_profile, self.main_class) then
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

	profile_config.set_active_profile(self.focus_item.text, self.main_class)
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
		self:_set_active_profile()
	end, { noremap = true, nowait = true })
	-- delete
	self.menu:map('n', 'd', function()
		self:_delete_profile()
	end, { noremap = true, nowait = true })
end

local M = {}

local async = require('java-core.utils.async').sync
local get_error_handler = require('java.handlers.error')

--- @type ProfileUI
M.ProfileUI = ProfileUI

function M.ui()
	return async(function()
			local configs = DapSetup(jdtls().client):get_dap_config()

			if not configs or #configs == 0 then
				notify.error('No classes with main methods are found')
				return
			end

			local selected_config = ui.select(
				'Select the main class (module -> mainClass)',
				configs,
				function(config)
					return config.name
				end
			)

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
