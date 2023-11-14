local M = {}

M.main_class = [[
(method_declaration
	(modifiers) @modifiers (#eq? @modifiers "public static")
	type: (void_type) @return_type
	name: (identifier) @name (#eq? @name "main")
	parameters: (formal_parameters
		(formal_parameter
			type: (array_type
				element: (type_identifier) @arg_type (#eq? @arg_type "String"))))
) @main_method
]]

return M
