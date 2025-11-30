```lua
{
  callHierarchyProvider = true,
  codeActionProvider = {
    resolveProvider = true
  },
  codeLensProvider = {
    resolveProvider = true
  },
  completionProvider = {
    completionItem = {
      labelDetailsSupport = true
    },
    resolveProvider = true,
    triggerCharacters = { ".", "@", "#", "*", " " }
  },
  definitionProvider = true,
  documentFormattingProvider = true,
  documentHighlightProvider = true,
  documentOnTypeFormattingProvider = {
    firstTriggerCharacter = ";",
    moreTriggerCharacter = { "\n", "}" }
  },
  documentRangeFormattingProvider = true,
  documentSymbolProvider = true,
  executeCommandProvider = {
    commands = {
        "java.completion.onDidSelect",
        "java.decompile",
        "java.edit.handlePasteEvent",
        "java.edit.organizeImports",
        "java.edit.smartSemicolonDetection",
        "java.edit.stringFormatting",
        "java.navigate.openTypeHierarchy",
        "java.navigate.resolveTypeHierarchy",
        "java.project.addToSourcePath",
        "java.project.createModuleInfo",
        "java.project.getAll",
        "java.project.getClasspaths",
        "java.project.getSettings",
        "java.project.import",
        "java.project.isTestFile",
        "java.project.listSourcePaths",
        "java.project.refreshDiagnostics",
        "java.project.removeFromSourcePath",
        "java.project.resolveSourceAttachment",
        "java.project.resolveStackTraceLocation",
        "java.project.resolveWorkspaceSymbol",
        "java.project.updateSourceAttachment",
        "java.project.upgradeGradle",
        "java.protobuf.generateSources",
        "java.reloadBundles",
        "vscode.java.buildWorkspace",
        "vscode.java.checkProjectSettings",
        "vscode.java.fetchPlatformSettings",
        "vscode.java.fetchUsageData",
        "vscode.java.inferLaunchCommandLength",
        "vscode.java.isOnClasspath",
        "vscode.java.resolveBuildFiles",
        "vscode.java.resolveClassFilters",
        "vscode.java.resolveClasspath",
        "vscode.java.resolveElementAtSelection",
        "vscode.java.resolveInlineVariables",
        "vscode.java.resolveJavaExecutable",
        "vscode.java.resolveMainClass",
        "vscode.java.resolveMainMethod",
        "vscode.java.resolveSourceUri",
        "vscode.java.startDebugSession",
        "vscode.java.test.findDirectTestChildrenForClass",
        "vscode.java.test.findJavaProjects",
        "vscode.java.test.findTestLocation",
        "vscode.java.test.findTestPackagesAndTypes",
        "vscode.java.test.findTestTypesAndMethods",
        "vscode.java.test.generateTests",
        "vscode.java.test.get.testpath",
        "vscode.java.test.junit.argument",
        "vscode.java.test.navigateToTestOrTarget",
        "vscode.java.test.resolvePath",
        "vscode.java.updateDebugSettings",
        "vscode.java.validateLaunchConfig",
    }
  },
  foldingRangeProvider = true,
  hoverProvider = true,
  implementationProvider = true,
  inlayHintProvider = true,
  referencesProvider = true,
  renameProvider = {
    prepareProvider = true
  },
  selectionRangeProvider = true,
  semanticTokensProvider = {
    documentSelector = { {
        language = "java",
        scheme = "file"
      }, {
        language = "java",
        scheme = "jdt"
      } },
    full = {
      delta = false
    },
    legend = {
      tokenModifiers = {
          "abstract",
          "constructor",
          "declaration",
          "deprecated",
          "documentation",
          "generic",
          "importDeclaration",
          "native",
          "private",
          "protected",
          "public",
          "readonly",
          "static",
          "typeArgument",
      },
      tokenTypes = {
          "annotation",
          "annotationMember",
          "class",
          "enum",
          "enumMember",
          "interface",
          "keyword",
          "method",
          "modifier",
          "namespace",
          "parameter",
          "property",
          "record",
          "recordComponent",
          "type",
          "typeParameter",
          "variable",
      }
    },
    range = false
  },
  signatureHelpProvider = {
    triggerCharacters = { "(", "," }
  },
  textDocumentSync = {
    change = 2,
    openClose = true,
    save = {
      includeText = true
    },
    willSave = true,
    willSaveWaitUntil = true
  },
  typeDefinitionProvider = true,
  typeHierarchyProvider = true,
  workspace = {
    workspaceFolders = {
      changeNotifications = true,
      supported = true
    }
  },
  workspaceSymbolProvider = true
}
```
