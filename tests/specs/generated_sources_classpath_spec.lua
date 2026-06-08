local assert = require('luassert')

describe('Generated sources classpath patcher', function()
	local classpath = require('java.experimental.fix-generated-sources')
	local path = require('java-core.utils.path')

	local temp_dir
	local module_root
	local classpath_file

	local function write_classpath(lines)
		vim.fn.writefile(lines, classpath_file)
	end

	local function read_classpath()
		return table.concat(vim.fn.readfile(classpath_file), '\n')
	end

	before_each(function()
		temp_dir = vim.fn.tempname()
		module_root = path.join(temp_dir, 'project')
		classpath_file = path.join(module_root, '.classpath')

		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'src', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'openapi', 'src', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'foo', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'openapi', 'main', 'java'), 'p')
		vim.fn.mkdir(path.join(module_root, 'target', 'generated-sources', 'java'), 'p')

		write_classpath({
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
		})
	end)

	after_each(function()
		vim.fn.delete(temp_dir, 'rf')
	end)

	it('adds only generated roots that end with src/{segment}/java and excludes them from the parent root', function()
		assert.is_true(classpath.patch(temp_dir))

		local content = read_classpath()

		assert.is_truthy(content:find('excluding="annotations/|openapi/|src/"', 1, true))
		assert.is_truthy(content:find('path="target/generated-sources/src/main/java"', 1, true))
		assert.is_truthy(content:find('path="target/generated-sources/openapi/src/main/java"', 1, true))
		assert.is_falsy(content:find('path="target/generated-sources/foo/main/java"', 1, true))
		assert.is_falsy(content:find('path="target/generated-sources/openapi/main/java"', 1, true))
		assert.is_falsy(content:find('path="target/generated-sources/java"', 1, true))
	end)

	it('does not add generated roots when the parent generated-sources entry is missing', function()
		write_classpath({
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
		})

		assert.is_false(classpath.patch(temp_dir))

		local content = read_classpath()
		assert.is_falsy(content:find('target/generated-sources/src/main/java', 1, true))
	end)

	it('is idempotent — second call returns false and leaves file unchanged', function()
		assert.is_true(classpath.patch(temp_dir))
		local after_first = read_classpath()

		assert.is_false(classpath.patch(temp_dir))
		local after_second = read_classpath()

		assert.equals(after_first, after_second)
	end)

	it('preserves pre-existing exclusions in the generated-sources entry', function()
		write_classpath({
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<classpath>',
			'\t<classpathentry kind="src" output="target/classes" path="src/main/java">',
			'\t\t<attributes>',
			'\t\t\t<attribute name="optional" value="true"/>',
			'\t\t\t<attribute name="maven.pomderived" value="true"/>',
			'\t\t</attributes>',
			'\t</classpathentry>',
			'\t<classpathentry excluding="custom/|other/" kind="src" output="target/classes" path="target/generated-sources">',
			'\t\t<attributes>',
			'\t\t\t<attribute name="optional" value="true"/>',
			'\t\t\t<attribute name="maven.pomderived" value="true"/>',
			'\t\t</attributes>',
			'\t</classpathentry>',
			'\t<classpathentry kind="output" path="target/classes"/>',
			'</classpath>',
		})

		assert.is_true(classpath.patch(temp_dir))

		local content = read_classpath()
		-- Original exclusions are preserved
		assert.is_truthy(content:find('custom/', 1, true))
		assert.is_truthy(content:find('other/', 1, true))
		-- New exclusions are added
		assert.is_truthy(content:find('annotations/', 1, true))
		assert.is_truthy(content:find('openapi/', 1, true))
		assert.is_truthy(content:find('src/', 1, true))
		-- Generated roots are still added
		assert.is_truthy(content:find('path="target/generated-sources/src/main/java"', 1, true))
	end)

	it('handles multi-module projects with multiple .classpath files', function()
		local module_b_root = path.join(temp_dir, 'module-b')
		local module_b_classpath = path.join(module_b_root, '.classpath')

		vim.fn.mkdir(path.join(module_b_root, 'target', 'generated-sources', 'grpc', 'src', 'main', 'java'), 'p')

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
		}, module_b_classpath)

		assert.is_true(classpath.patch(temp_dir))

		-- Module A (original) is patched
		local content_a = read_classpath()
		assert.is_truthy(content_a:find('path="target/generated-sources/src/main/java"', 1, true))

		-- Module B is also patched
		local content_b = table.concat(vim.fn.readfile(module_b_classpath), '\n')
		assert.is_truthy(content_b:find('path="target/generated-sources/grpc/src/main/java"', 1, true))
	end)
end)
