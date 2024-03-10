local Layout = require('nui.layout')
local Menu = require('nui.menu')
local Popup = require('nui.popup')
local notify = require('java-core.utils.notify')
local log = require('java.utils.log')
local async = require('java-core.utils.async').sync
local profile_config = require('java.api.profile_config').config
local get_error_handler = require('java.handlers.error')

local new_profile = 'New Profile'

--- @class ProfileUI
--- @field config ProjectConfig
--- @field win_options table
--- @field style string
local ProfileUI = {}
function ProfileUI:new(config)
	local o = {
		config = config,
		win_options = {
			winhighlight = 'Normal:Normal,FloatBorder:Normal',
		},
		style = 'single',
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ProfileUI:get_menu()
	local menu_itmes = {}
	local loop = self.config.profiles or {}

	local count = 1
	for key, _ in pairs(loop) do
		if self.config.profiles[key].is_active then
			key = key .. ' (active)'
			menu_itmes[1] = Menu.item(key)
		else
			count = count + 1
			menu_itmes[count] = Menu.item(key)
		end
	end
	table.insert(menu_itmes, Menu.separator())
	table.insert(menu_itmes, Menu.item(new_profile))
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
		lines = menu_itmes,
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
		on_close = function()
			print('Menu Closed! ')
		end,
		on_submit = function(item)
			if item.text == new_profile then
				self:_open_profile_editor()
			else
				local profile_name = item.text:gsub(' %(.+%)', '')
				self:_open_profile_editor(profile_name)
			end
		end,
	})
end

function ProfileUI._map_keys_for_profile_editor(pop, up_win, down_win)
	local function go_up()
		vim.api.nvim_set_current_win(up_win)
	end

	local function go_down()
		vim.api.nvim_set_current_win(down_win)
	end

	pop:map('n', '<Tab>', go_up)
	pop:map('n', 'k', go_up)
	pop:map('n', 'j', go_down)
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
			{ self.config.profiles[target_profile][key] }
		)
	end
	return popup
end

function ProfileUI:_fill_profile_popup(target_profile, popup)
	vim.api.nvim_buf_set_lines(
		popup.bufnr,
		0,
		-1,
		false,
		{ self.config.profiles[target_profile].name }
	)
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
			self:_save_profile(popups, target_profile)
			layout:unmount()
		end)
	end

	ProfileUI._map_keys_for_profile_editor(
		popups.name, -- pop (first)
		popups.prog_args.winid, -- up_win
		popups.vm_args.winid -- down_win
	)

	ProfileUI._map_keys_for_profile_editor(
		popups.vm_args, -- pop (second)
		popups.name.winid, -- up_win
		popups.prog_args.winid -- down_win
	)
	ProfileUI._map_keys_for_profile_editor(
		popups.prog_args, -- pop (third)
		popups.vm_args.winid, -- up_win
		popups.name.winid -- down_win
	)
end

function ProfileUI:_save_profile(popups, target_profile)
	async(function()
		local data = {}
		if target_profile then
			if target_profile:match('^(.*)(active)') then
				target_profile = target_profile:gsub(' %(.+%)', '')
			end
			data['is_active'] = self.config.profiles[target_profile] ~= nil
					and self.config.profiles[target_profile].is_active
				or false
			self.config.profiles[target_profile] = nil
		else
			-- new profile is active by default
			for key, _ in pairs(self.config.profiles) do
				self.config.profiles[key].is_active = false
			end
			data['is_active'] = target_profile == nil
		end

		for key, popup in pairs(popups) do
			local _, val =
				pcall(vim.api.nvim_buf_get_lines, popup.bufnr, 0, -1, false)
			data[key] = val[1]
		end
		if data['name'] == '' then
			notify.error('Profile name is required')
			return
		end

		self.config.profiles[data['name']] = data
		log.debug('new profiles: ', vim.inspect(data))
		log.debug('Updated profiles: ', vim.inspect(self.config.profiles))
		self.config:save()
		-- if new profile is active, need to reconfig dap to apply args
		if data['is_active'] then
			ProfileUI._config_dap()
		end
	end).run()
end

function ProfileUI._config_dap()
	async(function()
			require('java.api.dap').config_dap()
		end)
		.catch(get_error_handler('failed to config dap for new active profile'))
		.run()
end

function ProfileUI:_set_active_profile()
	if
		self.focus_item == nil
		or self.focus_item.text == nil
		or self.focus_item.text == new_profile
	then
		notify.error('Failed to set profile as active')
		return
	end

	if self.focus_item.text:match('^(.*)(active)') then
		return
	end
	for key, _ in pairs(self.config.profiles) do
		if self.config.profiles[key].is_active then
			self.config.profiles[key].is_active = false
			break
		end
	end
	self.config.profiles[self.focus_item.text].is_active = true
	self.config:save()
	ProfileUI._config_dap()
	self.menu:unmount()
	self:openMenu()
end

function ProfileUI:_delete_profile()
	if
		self.focus_item == nil
		or self.focus_item.text == nil
		or self.focus_item.text == new_profile
	then
		notify.error('Failed to delete profile')
		return
	end
	if self.focus_item.text:match('^(.*)(active)') then
		notify.error('Could not delete active profile')
	end

	self.config.profiles[self.focus_item.text] = nil
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
	-- save
	-- self.menu:map('n', 's', function()
	-- 	self.config:save()
	-- 	self.menu:unmount()
	-- end, { noremap = true, nowait = true })
	-- set active
	self.menu:map('n', 'a', function()
		self:_set_active_profile()
	end, { noremap = true, nowait = true })
	-- delete
	self.menu:map('n', 'd', function()
		self:_delete_profile()
	end, { noremap = true, nowait = true })
end

local M = {}

function M.ui()
	M.profile_ui = ProfileUI:new(profile_config)
	return M.profile_ui:openMenu()
end

return M
