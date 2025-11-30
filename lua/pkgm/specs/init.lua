local BaseSpec = require('pkgm.specs.base-spec')
local JdtlsSpec = require('pkgm.specs.jdtls-spec')

---@class pkgm.PackageSpec
---@field get_name fun(self: pkgm.PackageSpec): string
---@field get_version fun(self: pkgm.PackageSpec): string
---@field get_url fun(self: pkgm.PackageSpec, name: string, version: string): string
---@field is_match fun(self: pkgm.PackageSpec, name: string, version: string): boolean

return {
	JdtlsSpec({
		name = 'jdtls',
		version_range = { from = '1.43.0', to = '1.53.0' },
		url = 'https://download.eclipse.org/{{name}}/milestones/'
			.. '{{version}}/jdt-language-server-{{version}}-{{timestamp}}.tar.gz',
	}),
	BaseSpec({
		name = 'java-test',
		version = '*',
		url = 'https://openvsxorg.blob.core.windows.net/resources/vscjava/vscode-java-test'
			.. '/{{version}}/vscjava.vscode-java-test-{{version}}.vsix',
	}),

	BaseSpec({
		name = 'java-debug',
		version = '*',
		url = 'https://openvsxorg.blob.core.windows.net/resources/vscjava/vscode-java-debug/'
			.. '{{version}}/vscjava.vscode-java-debug-{{version}}.vsix',
	}),

	BaseSpec({
		name = 'spring-boot-tools',
		version = '*',
		url = 'https://openvsxorg.blob.core.windows.net/resources/VMware/vscode-spring-boot'
			.. '/{{version}}/VMware.vscode-spring-boot-{{version}}.vsix',
	}),

	BaseSpec({
		name = 'lombok',
		version = 'nightly',
		url = 'https://projectlombok.org/lombok-edge.jar',
	}),

	BaseSpec({
		name = 'lombok',
		version = '*',
		url = 'https://projectlombok.org/downloads/lombok-{{version}}.jar',
	}),

	BaseSpec({
		name = 'openjdk',
		version = '17',
		full_version = '17.0.12',
		urls = {
			linux = {
				arm = {
					['64bit'] = 'https://download.oracle.com/java/{{version}}/archive/jdk-{{full_version}}_linux-aarch64_bin.tar.gz',
				},
				x86 = {
					['64bit'] = 'https://download.oracle.com/java/{{version}}/archive/jdk-{{full_version}}_linux-x64_bin.tar.gz',
				},
			},
			mac = {
				arm = {
					['64bit'] = 'https://download.oracle.com/java/{{version}}/archive/jdk-{{full_version}}_macos-aarch64_bin.tar.gz',
				},
				x86 = {
					['64bit'] = 'https://download.oracle.com/java/{{version}}/archive/jdk-{{full_version}}_macos-x64_bin.tar.gz',
				},
			},
			win = {
				x86 = {
					['64bit'] = 'https://download.oracle.com/java/{{version}}/archive/jdk-{{full_version}}_windows-x64_bin.zip',
				},
			},
		},
	}),
}
