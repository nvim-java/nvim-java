# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Guidelines

- Be extremely concise in all interactions and commit messages
- Sacrifice grammar for sake of concision
- Keep CLAUDE.md updated when changes make it outdated; add noteworthy patterns/conventions after implementing changes

## Documentation

Additional documentation available in `/doc`:
- `development.md` - Development environment setup (devcontainer, Spring Boot test projects)
- `nvim-java.txt` - Plugin documentation
- `server-capabilities.md` - Server capabilities reference
- `ts-to-lua-guide.md` - TypeScript to Lua translation guide

## Build Commands

```bash
make tests            # Run Plenary/Busted tests (headless Neovim)
make test FILE=path   # Run specific test file
make lint             # Run luacheck linter
make format           # Format with stylua
make all              # lint -> format -> tests
```

## Architecture

nvim-java is a Neovim plugin providing Java IDE features via JDTLS wrapper. Monorepo structure with bundled submodules:

```
lua/
├── java.lua              # Main API entry point
├── java/                 # Core plugin (startup, config, api/, runner/, ui/, utils/)
├── java-core/            # LSP integration (ls/servers/jdtls/, clients/, adapters/, utils/)
├── java-test/            # Test runner (ui/, results/, reports/)
├── java-dap/             # Debug adapter (api/, data/)
├── java-refactor/        # Refactoring tools (api/, client-commands/)
├── pkgm/                 # Package management (downloaders/, extractors/, version control)
└── async/                # Custom async/await wrapper
plugin/java.lua           # User command registration
```

**java-core Details:**
- Core JDTLS features implementation
- `ls/servers/jdtls/` - JDTLS config generator, loads extensions (java-test, java-debug, spring-boot, lombok). Uses mason.nvim APIs for extension paths
- `ls/clients/` - LSP request wrappers:
  - `jdtls-client.lua` - Core JDTLS LSP calls
  - `java-test-client.lua`, `java-debug-client.lua` - Extension-specific calls
  - Purpose: wrap async APIs with coroutines for sync-style calls, add typing
  - 1:1 mappings of VSCode projects for Neovim:
    - vscode-java, vscode-java-test, vscode-java-debug

**pkgm Details:**
- Package management utilities
- `downloaders/` - Download implementations (wget, etc.)
- `extractors/` - Archive extraction utilities
- Version control and package lifecycle management
- `specs/jdtls-spec/version-map.lua` - JDTLS version to timestamp mapping

**Updating JDTLS Versions:**
1. Visit https://download.eclipse.org/jdtls/milestones/
2. Click version link in 'Directory Contents' section
3. Find file: `jdt-language-server-X.Y.Z-YYYYMMDDHHSS.tar.gz`
4. Extract version (X.Y.Z) and timestamp (YYYYMMDDHHSS)
5. Add to `version-map.lua`: `['X.Y.Z'] = 'YYYYMMDDHHSS'`

**Key Files:**
- `lua/java/config.lua` - Default configuration (JDTLS version, plugins, JDK)
- `lua/java-core/ls/servers/jdtls/config.lua` - JDTLS server configuration
- `lazy.lua` - lazy.nvim plugin spec with dependencies

## Test Structure

```
tests/
├── assets/           # Test fixtures and assets (e.g., HelloWorld.java)
├── constants/        # Test constants (e.g., capabilities.lua)
├── utils/            # Test utilities and config files
│   ├── lsp-utils.lua      # LSP test helpers
│   ├── prepare-config.lua # Lazy.nvim test setup
│   └── test-config.lua    # Manual test setup
└── specs/            # Test specifications
    ├── lsp_spec.lua       # All LSP-related tests
    └── pkgm_spec.lua      # All pkgm-related tests
```

**Test Guidelines:**
- Group related tests in single spec file (e.g., all pkgm tests in `pkgm_spec.lua`)
- Extract reusable logic to `utils/` to keep test steps clean
- Store test data/fixtures in `assets/`
- Store constants (capabilities, expected values) in `constants/`

## Code Patterns

**Event-driven registration:** Modules register on JDTLS attach via `event.on_jdtls_attach()`

**Config merging:** `vim.tbl_deep_extend('force', global_config, user_config or {})`

**Config type sync:** When modifying `lua/java/config.lua` (add/update/delete properties), update both `java.Config` type and `java.PartialConfig` in `lua/java.lua` to keep types in sync

**Complex types:** If type contains complex object, create class type instead of inlining type everywhere

**Async operations:** Uses custom async/await in `lua/async/` instead of raw coroutines

**User commands:** Registered in `plugin/java.lua`, map to nested API in `lua/java/api/`

**Class creation:** Use `java-core/utils/class` (Penlight class system):
```lua
local class = require('java-core.utils.class')

local Base = class()
function Base:_init(name)
  self.name = name
end

local Child = class(Base)
function Child:_init(name, age)
  self:super(name)
  self.age = age
end
```

**Logging:** Use `java-core/utils/log2` for all logging:
```lua
local log = require('java-core.utils.log2')
log.trace('trace message')
log.debug('debug message')
log.info('info message')
log.warn('warning message')
log.error('error message')
log.fatal('fatal message')
```

## Code Style

- Tabs for indentation (tab width: 2)
- Line width: 80 chars
- Single quotes preferred
- LuaDoc annotations (`---@`) for types
- Type naming: Prefix types with package name (e.g., `java.Config`, `java-debug.DebugConfig`)
- Neovim globals allowed: vim.o, vim.g, vim.wo, vim.bo, vim.opt, vim.lsp
- Private methods: Use `@private` annotation, NOT `_` prefix (except `_init` constructor)
- Method syntax: Always use `:` for class methods regardless of `self` usage
  - All class methods: `function ClassName:method_name()` (with or without `self`)

## Git Guidelines

- Use conventional commit messages per [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- `feat:` is ONLY for end-user features (e.g., `feat: add code completion`)
  - CI/internal features use `chore(ci):` (e.g., `chore(ci): enable debug logs`)
  - Build/tooling features use `chore(build):`, `chore(test):`, etc.
- Never append "generated by AI" message
- Split unrelated changes into separate commits
