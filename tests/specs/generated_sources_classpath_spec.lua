local assert = require('luassert')

describe('Generated sources classpath patcher', function()
	local classpath = require('java.experimental.fix-generated-sources')
	local path = require('java-core.utils.path')

	local temp_dir
	local module_root
	local classpath_file

	before_each(function()
		temp_dir = vim.fn.tempname()
		module_root = path.join(temp_dir, 'project')
		classpath_file = path.join(module_root, '.classpath')

		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'src', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'openapi', 'src', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'foo', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'openapi', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'java'), 'p')

		vim.fn.writefile({
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<classpath>',
			'\t<classpathentry kind="src" output="target/classes" path="src/main/java">',
			'\t\t<attributes>',
			'\t\t\t<attribute name="optional" value="true"/>',
			'\t\t\t<attribute name="maven.pomderived" value="true"/>',
			'\t\t</attributes>',
			'\t</classpathentry>',
			'\t<classpathentry kind="src" output="target/classes" path="target/generated-sources">',
			'\t\t<attributes>',
			'\t\t\t<attribute name="optional" value="true"/>',
			'\t\t\t<attribute name="maven.pomderived" value="true"/>',
			'\t\t</attributes>',
			'\t</classpathentry>',
			'\t<classpathentry kind="output" path="target/classes"/>',
			'</classpath>',
		}, classpath_file)
	end)

	after_each(function()
		vim.fn.delete(temp_dir, 'rf')
	end)

	it('adds only generated roots that end with src/{segment}/java and excludes them from the parent root', function()
		assert.is_true(classpath.patch(temp_dir))

		local lines = vim.fn.readfile(classpath_file)
		local content = table.concat(lines, '\n')

		assert.is_truthy(content:find('excluding="annotations/|openapi/|src/"', 1, true))
		assert.is_truthy(content:find('path="target/generated-sources/src/main/java"', 1, true))
		assert.is_truthy(content:find('path="target/generated-sources/openapi/src/main/java"', 1, true))
		assert.is_falsy(content:find('path="target/generated-sources/foo/main/java"', 1, true))
		assert.is_falsy(content:find('path="target/generated-sources/openapi/main/java"', 1, true))
		assert.is_falsy(content:find('path="target/generated-sources/java"', 1, true))
	end)

	it('does not add generated roots when the parent generated-sources entry is missing', function()
		vim.fn.writefile({
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<classpath>',
			'\t<classpathentry kind="src" output="target/classes" path="src/main/java">',
			'\t\t<attributes>',
			'\t\t\t<attribute name="optional" value="true"/>',
			'\t\t\t<attribute name="maven.pomderived" value="true"/>',
			'\t\t</attributes>',
			'\t</classpathentry>',
			'\t<classpathentry kind="output" path="target/classes"/>',
			'</classpath>',
		}, classpath_file)

		assert.is_false(classpath.patch(temp_dir))

		local content = table.concat(vim.fn.readfile(classpath_file), '\n')
		assert.is_falsy(content:find('target/generated-sources/src/main/java', 1, true))
	end)
end)
