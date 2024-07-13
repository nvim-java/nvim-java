local log = require('java.utils.log')

local M = {}

local id

id = vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if client and client.name == 'jdtls' then
			log.debug('adding vim.lsp.commands for java')

			for key, handler in pairs(M.handlers) do
				vim.lsp.commands[key] = handler
			end

			vim.api.nvim_del_autocmd(id)
		end
	end,

	group = vim.api.nvim_create_augroup('JavaCommandReg', {}),
})

M.commands = {

	OPEN_BROWSER = 'vscode.open',

	OPEN_OUTPUT = 'java.open.output',

	SHOW_JAVA_REFERENCES = 'java.show.references',

	SHOW_JAVA_IMPLEMENTATIONS = 'java.show.implementations',

	SHOW_REFERENCES = 'editor.action.showReferences',

	GOTO_LOCATION = 'editor.action.goToLocations',

	MARKDOWN_API_RENDER = 'markdown.api.render',

	CONFIGURATION_UPDATE = 'java.projectConfiguration.update',

	IGNORE_INCOMPLETE_CLASSPATH = 'java.ignoreIncompleteClasspath',

	IGNORE_INCOMPLETE_CLASSPATH_HELP = 'java.ignoreIncompleteClasspath.help',

	RELOAD_WINDOW = 'workbench.action.reloadWindow',

	PROJECT_CONFIGURATION_STATUS = 'java.projectConfiguration.status',

	NULL_ANALYSIS_SET_MODE = 'java.compile.nullAnalysis.setMode',

	APPLY_WORKSPACE_EDIT = 'java.apply.workspaceEdit',

	EXECUTE_WORKSPACE_COMMAND = 'java.execute.workspaceCommand',

	COMPILE_WORKSPACE = 'java.workspace.compile',

	BUILD_PROJECT = 'java.project.build',

	OPEN_SERVER_LOG = 'java.open.serverLog',

	OPEN_SERVER_STDOUT_LOG = 'java.open.serverStdoutLog',

	OPEN_SERVER_STDERR_LOG = 'java.open.serverStderrLog',

	OPEN_CLIENT_LOG = 'java.open.clientLog',

	OPEN_LOGS = 'java.open.logs',

	OPEN_FORMATTER = 'java.open.formatter.settings',

	OPEN_FILE = 'java.open.file',

	CLEAN_WORKSPACE = 'java.clean.workspace',

	UPDATE_SOURCE_ATTACHMENT_CMD = 'java.project.updateSourceAttachment.command',
	UPDATE_SOURCE_ATTACHMENT = 'java.project.updateSourceAttachment',

	RESOLVE_SOURCE_ATTACHMENT = 'java.project.resolveSourceAttachment',

	ADD_TO_SOURCEPATH_CMD = 'java.project.addToSourcePath.command',
	ADD_TO_SOURCEPATH = 'java.project.addToSourcePath',

	REMOVE_FROM_SOURCEPATH_CMD = 'java.project.removeFromSourcePath.command',
	REMOVE_FROM_SOURCEPATH = 'java.project.removeFromSourcePath',

	LIST_SOURCEPATHS_CMD = 'java.project.listSourcePaths.command',
	LIST_SOURCEPATHS = 'java.project.listSourcePaths',

	IMPORT_PROJECTS_CMD = 'java.project.import.command',
	IMPORT_PROJECTS = 'java.project.import',
	CHANGE_IMPORTED_PROJECTS = 'java.project.changeImportedProjects',

	OVERRIDE_METHODS_PROMPT = 'java.action.overrideMethodsPrompt',

	HASHCODE_EQUALS_PROMPT = 'java.action.hashCodeEqualsPrompt',

	OPEN_JSON_SETTINGS = 'workbench.action.openSettingsJson',

	ORGANIZE_IMPORTS = 'java.action.organizeImports',

	ORGANIZE_IMPORTS_SILENTLY = 'java.edit.organizeImports',
	MANUAL_CLEANUP = 'java.action.doCleanup',

	HANDLE_PASTE_EVENT = 'java.edit.handlePasteEvent',

	CLIPBOARD_ONPASTE = 'java.action.clipboardPasteAction',

	FILESEXPLORER_ONPASTE = 'java.action.filesExplorerPasteAction',

	CHOOSE_IMPORTS = 'java.action.organizeImports.chooseImports',

	GENERATE_TOSTRING_PROMPT = 'java.action.generateToStringPrompt',

	GENERATE_ACCESSORS_PROMPT = 'java.action.generateAccessorsPrompt',

	GENERATE_CONSTRUCTORS_PROMPT = 'java.action.generateConstructorsPrompt',

	GENERATE_DELEGATE_METHODS_PROMPT = 'java.action.generateDelegateMethodsPrompt',

	APPLY_REFACTORING_COMMAND = 'java.action.applyRefactoringCommand',

	RENAME_COMMAND = 'java.action.rename',

	NAVIGATE_TO_SUPER_IMPLEMENTATION_COMMAND = 'java.action.navigateToSuperImplementation',

	SHOW_TYPE_HIERARCHY = 'java.action.showTypeHierarchy',

	SHOW_SUPERTYPE_HIERARCHY = 'java.action.showSupertypeHierarchy',

	SHOW_SUBTYPE_HIERARCHY = 'java.action.showSubtypeHierarchy',

	SHOW_CLASS_HIERARCHY = 'java.action.showClassHierarchy',

	CHANGE_BASE_TYPE = 'java.action.changeBaseType',

	OPEN_TYPE_HIERARCHY = 'java.navigate.openTypeHierarchy',

	RESOLVE_TYPE_HIERARCHY = 'java.navigate.resolveTypeHierarchy',

	SHOW_SERVER_TASK_STATUS = 'java.show.server.task.status',

	GET_PROJECT_SETTINGS = 'java.project.getSettings',

	GET_CLASSPATHS = 'java.project.getClasspaths',

	IS_TEST_FILE = 'java.project.isTestFile',

	GET_ALL_JAVA_PROJECTS = 'java.project.getAll',

	SWITCH_SERVER_MODE = 'java.server.mode.switch',

	RESTART_LANGUAGE_SERVER = 'java.server.restart',

	LEARN_MORE_ABOUT_REFACTORING = '_java.learnMoreAboutRefactorings',

	LEARN_MORE_ABOUT_CLEAN_UPS = '_java.learnMoreAboutCleanUps',

	TEMPLATE_VARIABLES = '_java.templateVariables',

	NOT_COVERED_EXECUTION = '_java.notCoveredExecution',

	METADATA_FILES_GENERATION = '_java.metadataFilesGeneration',

	RUNTIME_VALIDATION_OPEN = 'java.runtimeValidation.open',

	RESOLVE_WORKSPACE_SYMBOL = 'java.project.resolveWorkspaceSymbol',

	GET_WORKSPACE_PATH = '_java.workspace.path',

	UPGRADE_GRADLE_WRAPPER_CMD = 'java.project.upgradeGradle.command',
	UPGRADE_GRADLE_WRAPPER = 'java.project.upgradeGradle',

	LOMBOK_CONFIGURE = 'java.lombokConfigure',

	CREATE_MODULE_INFO = 'java.project.createModuleInfo',

	CREATE_MODULE_INFO_COMMAND = 'java.project.createModuleInfo.command',

	REFRESH_BUNDLES = 'java.reloadBundles',

	REFRESH_BUNDLES_COMMAND = '_java.reloadBundles.command',

	CLEAN_SHARED_INDEXES = 'java.clean.sharedIndexes',

	GET_DECOMPILED_SOURCE = 'java.decompile',

	SMARTSEMICOLON_DETECTION = 'java.edit.smartSemicolonDetection',

	RESOLVE_PASTED_TEXT = 'java.project.resolveText',

	OPEN_STATUS_SHORTCUT = '_java.openShortcuts',
}

M.handlers = {
	---@param _ lsp.Command
	---@param params nvim.CodeActionParamsResponse
	[M.commands.GENERATE_CONSTRUCTORS_PROMPT] = function(_, params)
		require('java.api.generate').generate_constructor(params)
	end,

	---@param is_full_build boolean
	[M.commands.COMPILE_WORKSPACE] = function(is_full_build)
		require('java.api.build').full_build_workspace(is_full_build)
	end,
}
