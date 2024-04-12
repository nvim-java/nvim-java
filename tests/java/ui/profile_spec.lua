local spy = require('luassert.spy')
local Menu = require('nui.menu')
local class = require('java-core.utils.class')

describe('java.ui.profile', function()
	local default_win_options = {
		winhighlight = 'Normal:Normal,FloatBorder:Normal',
	}
	local default_style = 'single'

	-- profile_config mock
	local profile_config = {
		Profile = function(vm_args, prog_args, name, is_active)
			return {
				vm_args = vm_args,
				prog_args = prog_args,
				name = name,
				is_active = is_active,
			}
		end,
		get_profile = function()
			return {}
		end,
		get_all_profiles = function()
			return {}
		end,
	}

	-- notify mock
	local notify = {
		warn = function() end,
		error = function() end,
	}

	-- dap mock
	local dap = {
		config_dap = function() end,
	}

	-- NuiMenu mock
	local MockMenu = class()
	function MockMenu:_init(table1, table2)
		self.table1 = table1
		self.table2 = table2
	end
	function MockMenu.on() end
	function MockMenu.unmount() end
	function MockMenu.map() end
	function MockMenu.mount() end

	before_each(function()
		package.loaded['java.api.profile_config'] = nil
		package.loaded['java.ui.profile'] = nil
		package.loaded['java-core.utils.notify'] = notify
	end)

	it('get_tree_node_list_for_menu', function()
		local expected_menu_items = {
			Menu.item('name2 (active)'),
			Menu.item('name'),
			Menu.separator(),
			Menu.item('New Profile'),
		}

		profile_config.get_all_profiles = function()
			return {
				name = profile_config.Profile('vm_args', 'prog_args', 'name', false),
				name2 = profile_config.Profile('vm_args2', 'prog_args2', 'name2', true),
			}
		end
		package.loaded['java.api.profile_config'] = profile_config

		local profile_ui = require('java.ui.profile')
		local ui = profile_ui.ProfileUI('main_class')
		local items = ui:get_tree_node_list_for_menu()

		for key, value in pairs(items) do
			assert.same(expected_menu_items[key].text, value.text)
			assert.same(expected_menu_items[key]._type, value._type)
		end
	end)

	it('get_menu', function()
		package.loaded['nui.menu'] = MockMenu
		local profile_ui = require('java.ui.profile')
		local ui = profile_ui.ProfileUI()

		ui.get_tree_node_list_for_menu = function()
			return { menu_list = 'mock_menu_list' }
		end

		local menu = ui:get_menu()

		assert.same(menu.table2.lines, { menu_list = 'mock_menu_list' })
		assert.same(menu.table1.border.text.top, '[Profiles]')
		assert.same(
			menu.table1.border.text.bottom,
			'[a]ctivate [d]elete [b]ack [q]uit'
		)
		assert(menu.table2.on_submit ~= nil)
	end)

	describe('_get_and_fill_popup', function()
		it('successfully', function()
			local spy_nvim_api = spy.on(vim.api, 'nvim_buf_set_lines')

			profile_config.get_profile = function(name, main_class)
				assert.same(name, 'target_profile')
				assert.same(main_class, 'main_class')
				return profile_config.Profile('vm_args', 'prog_args', 'name', false)
			end
			package.loaded['java.api.profile_config'] = profile_config

			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI('main_class')
			local popup = ui:_get_and_fill_popup('Title', 'name', 'target_profile')

			assert
				.spy(spy_nvim_api)
				.was_called_with(popup.bufnr, 0, -1, false, { 'name' })
			spy_nvim_api:revert()

			assert.same(popup.border._.text.top._content, '[Title]')
			assert.same(popup.border._.text.top_align, 'center')
			assert.same(popup.border._.winhighlight, default_win_options.winhighlight)
			assert.same(popup.border._.style, default_style)
		end)

		it('when target_profile is nil', function()
			local spy_nvim_api = spy.on(vim.api, 'nvim_buf_set_lines')
			profile_config.get_profile = function(_, _)
				return profile_config.Profile('vm_args', 'prog_args', 'name', false)
			end
			package.loaded['java.api.profile_config'] = profile_config

			local profile_ui = require('java.ui.profile')
			profile_ui.ProfileUI()
			assert.spy(spy_nvim_api).was_not_called()
			spy_nvim_api:revert()
		end)
	end)

	it('_open_profile_editor', function()
		package.loaded['java.api.profile_config'] = profile_config

		-- mock popup
		local MockPopup = class()
		function MockPopup:_init(options)
			self.border = options.border
			self.enter = options.enter
			self.win_options = options.win_options
			self.bufnr = 1
			self.map_list = {}
		end

		function MockPopup:map(mode, key, callback)
			table.insert(
				self.map_list,
				{ mode = mode, key = key, callback = callback }
			)
		end
		package.loaded['nui.popup'] = MockPopup

		-- mock layout
		local MockLayout = class()
		function MockLayout:_init(layout_settings, layout_box_list)
			self.layout_settings = layout_settings
			self.layout_box_list = layout_box_list
		end

		local boxes = {}
		function MockLayout.Box(box, options)
			table.insert(boxes, { box = box, options = options })
			return {}
		end

		function MockLayout.mount() end
		local spy_mockLayout_mount = spy.on(MockLayout, 'mount')

		package.loaded['nui.layout'] = MockLayout

		local profile_ui = require('java.ui.profile')
		local ui = profile_ui.ProfileUI()
		ui:_open_profile_editor('target_profile')

		-- verify Layout mount call
		assert.spy(spy_mockLayout_mount).was_called()

		-- verify Layout.Box calls
		assert.same(boxes[1].box.border.text.top, '[Name]')
		assert.same(boxes[2].box.border.text.top, '[VM arguments]')
		assert.same(boxes[3].box.border.text.top, '[Program arguments]')
		assert.same(boxes[3].box.border.text.bottom, '[s]ave [b]ack [q]uit')
		assert.same(boxes[3].box.border.text.bottom_align, 'center')

		assert.same(boxes[1].options, { grow = 0.2 })
		assert.same(boxes[2].options, { grow = 0.4 })
		assert.same(boxes[3].options, { grow = 0.4 })

		-- loop in popup.map calls
		for i = 1, 3 do
			local list = boxes[i].box.map_list
			-- verify keybindings

			-- actions
			-- back
			assert.same(list[1].mode, 'n')
			assert.same(list[1].key, 'b')
			assert(list[1].callback ~= nil)

			assert.same(list[2].mode, 'n')
			assert.same(list[2].key, 'q')
			assert(list[2].callback ~= nil)

			assert.same(list[3].mode, 'n')
			assert.same(list[3].key, 's')
			assert(list[3].callback ~= nil)

			-- navigation
			assert.same(list[4].mode, 'n')
			assert.same(list[4].key, '<Tab>')
			assert(list[4].callback ~= nil)

			assert.same(list[5].mode, 'n')
			assert.same(list[5].key, 'k')
			assert(list[5].callback ~= nil)

			assert.same(list[6].mode, 'n')
			assert.same(list[6].key, 'j')
			assert(list[6].callback ~= nil)
		end
	end)

	describe('_set_active_profile', function()
		it('successfully', function()
			-- mock profile_config
			local new_profile = 'mock_new_profile'
			profile_config.set_active_profile = function(name)
				assert.same(name, new_profile)
			end
			package.loaded['java.api.profile_config'] = profile_config
			package.loaded['java.api.dap'] = dap

			local spy_dap = spy.on(dap, 'config_dap')
			local spy_mockMenu = spy.on(MockMenu, 'unmount')

			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI()
			-- set up mock in ui
			ui.menu = MockMenu()
			local openMenu_call = 0
			ui.openMenu = function()
				openMenu_call = openMenu_call + 1
			end
			ui.focus_item = { text = new_profile }

			-- call function
			ui:_set_active_profile()

			--verify
			assert.spy(spy_mockMenu).was_called()
			assert.spy(spy_dap).was_called()
		end)

		it('when selected profile is not modifiable', function()
			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI()

			ui._is_selected_profile_modifiable = function()
				return false
			end
			ui:_set_active_profile()
		end)

		it('when selected profile active', function()
			local spy_notify = spy.on(notify, 'error')
			local spy_profile_config = spy.on(profile_config, 'set_active_profile')

			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI()

			ui._is_selected_profile_modifiable = function()
				return true
			end

			ui.focus_item = { text = 'mock (active)' }
			ui:_set_active_profile()
			assert.spy(spy_notify).was_not_called()
			assert.spy(spy_profile_config).was_not_called()
		end)
	end)

	describe('_delete_profile', function()
		it('successfully', function()
			-- mock profile_config
			local new_profile = 'mock_new_profile'
			profile_config.delete_profile = function(name)
				assert.same(name, new_profile)
			end
			package.loaded['java.api.profile_config'] = profile_config

			local spy_mockMenu = spy.on(MockMenu, 'unmount')

			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI()

			-- set up mock in ui
			ui.menu = MockMenu()
			local openMenu_call = 0
			ui.openMenu = function()
				openMenu_call = openMenu_call + 1
			end
			ui.focus_item = { text = new_profile }

			-- call function
			ui:_delete_profile()

			--verify
			assert.spy(spy_mockMenu).was_called()
		end)

		it('when selected profile is not modifiable', function()
			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI()

			ui._is_selected_profile_modifiable = function()
				return false
			end
			ui:_delete_profile()
		end)

		it('when selected profile active', function()
			local spy_notify = spy.on(notify, 'warn')
			local spy_profile_config = spy.on(profile_config, 'delete_profile')

			local profile_ui = require('java.ui.profile')
			local ui = profile_ui.ProfileUI()

			ui.focus_item = { text = 'mock (active)' }
			ui:_delete_profile()
			assert.spy(spy_notify).was_called_with('Cannot delete active profile')
			assert.spy(spy_profile_config).was_not_called()
		end)
	end)

	describe('_is_selected_profile_modifiable when ', function()
		local profile_ui = require('java.ui.profile')
		local ui = profile_ui.ProfileUI()

		it('focus_item is nil', function()
			ui:_is_selected_profile_modifiable()
			assert.same(ui:_is_selected_profile_modifiable(), false)
		end)

		it('focus_item.text is nil', function()
			ui.focus_item = { text = nil }
			ui:_is_selected_profile_modifiable()
			assert.same(ui:_is_selected_profile_modifiable(), false)
		end)

		it('focus_item.text is new_profile', function()
			ui.focus_item = { text = 'New Profile' }
			ui:_is_selected_profile_modifiable()
			assert.same(ui:_is_selected_profile_modifiable(), false)
		end)
	end)

	it('openMenu', function()
		-- mock Menu
		local spy_on_mount = spy.on(MockMenu, 'mount')
		local spy_on_map = spy.on(MockMenu, 'map')
		-- mock profile_ui
		local profile_ui = require('java.ui.profile')
		local ui = profile_ui.ProfileUI()
		ui.get_menu = function()
			return MockMenu()
		end

		ui:openMenu()

		assert.spy(spy_on_mount).was_called(1)
		assert.spy(spy_on_map).was_called(4)

		-- verify keybindings
		-- quit
		assert.same(spy_on_map.calls[1].refs[2], 'n')
		assert.same(spy_on_map.calls[1].refs[3], 'q')
		assert(spy_on_map.calls[1].refs[4] ~= nil)

		-- back
		assert.same(spy_on_map.calls[2].refs[2], 'n')
		assert.same(spy_on_map.calls[2].refs[3], 'b')
		assert(spy_on_map.calls[2].refs[4] ~= nil)

		-- set active profile
		assert.same(spy_on_map.calls[3].refs[2], 'n')
		assert.same(spy_on_map.calls[3].refs[3], 'a')
		assert(spy_on_map.calls[3].refs[4] ~= nil)

		-- delete profile
		assert.same(spy_on_map.calls[4].refs[2], 'n')
		assert.same(spy_on_map.calls[4].refs[3], 'd')
		assert(spy_on_map.calls[4].refs[4] ~= nil)
	end)
end)
