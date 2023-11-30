# :coffee: nvim-java

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Gradle](https://img.shields.io/badge/Gradle-02303A.svg?style=for-the-badge&logo=Gradle&logoColor=white)
![Apache Maven](https://img.shields.io/badge/Apache%20Maven-C71A36?style=for-the-badge&logo=Apache%20Maven&logoColor=white)

No need to put up with [jdtls](https://github.com/eclipse-jdtls/eclipse.jdt.ls) nonsense anymore.
Just install and start writing `public static void main(String[] args)`.

## :dizzy: Features

- :white_check_mark: Diagnostics & Auto Completion
- :white_check_mark: Automatic [DAP](https://github.com/mfussenegger/nvim-dap) debug configuration
- :white_check_mark: Running tests

## :bulb: Why

- Uses [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) to setup `jdtls`
- Realtime server settings updates is possible using [neoconf](https://github.com/folke/neoconf.nvim)
- Everything necessary will be installed automatically (except JDKs)
- Uses `jdtls` and auto loads `jdtls` plugins from [mason.nvim](https://github.com/williamboman/mason.nvim)
  - Supported plugins are,
    - `lombok`
    - `java-test`
    - `java-debug-adapter`
- Typed & documented APIs

## :hammer: How to Install

<details>

<summary>:pushpin: details</summary>

**Pre-requisites**

- [Python 3.9](https://www.python.org/downloads/) - for running `jdtls` wrapper launch script

**Install the plugin**

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'nvim-java/nvim-java',
  dependencies = {
    'nvim-java/nvim-java-core',
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
    'mfussenegger/nvim-dap',
  },
  event = 'VeryLazy',
  opts = {},
}
```

**Setup jdtls like you would usually do**

```lua
require('lspconfig').jdtls.setup({})
```

Yep! That's all :)

</details>

## :computer: APIs

<details>

<summary>:pushpin: details</summary>

**DAP**

- `config_dap` - DAP is autoconfigured on start up, but in case you want to force configure it again, you can use this API

```lua
require('java').dap.config_dap()
```

**Test**

- `run_current_class` - Run the test class in the active buffer

```lua
require('java').test.run_current_class()
```

- `debug_current_class` - Debug the test class in the active buffer

```lua
require('java').test.debug_current_class()
```

- `run_current_method` - Run the test method on the cursor

```lua
require('java').test.run_current_method()
```

- `debug_current_method` - Debug the test method on the cursor

```lua
require('java').test.debug_current_method()
```

- `view_report` - Open the last test report in a popup window

```lua
require('java').test.view_report()
```

</details>

## :bookmark_tabs: Projects Acknowledgement

[nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) is a plugin that follows "Keep it simple, stupid!" approach.
If you love customizing things by yourself, then give nvim-jdtls a try. I may or may not have copied some code :wink:
Beauty of Open source!
