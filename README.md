# nvim-java

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Gradle](https://img.shields.io/badge/Gradle-02303A.svg?style=for-the-badge&logo=Gradle&logoColor=white)
![Apache Maven](https://img.shields.io/badge/Apache%20Maven-C71A36?style=for-the-badge&logo=Apache%20Maven&logoColor=white)

No need to put up with [jdtls](https://github.com/eclipse-jdtls/eclipse.jdt.ls) nonsense anymore.
Just install and start writing `public static void main(String[] args)`.

## Features

- :white_check_mark: Diagnostics & Auto Completion
- :white_check_mark: Automatic [DAP](https://github.com/mfussenegger/nvim-dap) debug configuration
- :x: Running tests

## Why

- Uses [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) to setup `jdtls`
- Realtime server settings updates is possible using [neoconf](https://github.com/folke/neoconf.nvim)
- Everything necessary will be installed automatically (except JDKs)
- Uses `jdtls` and auto loads `jdtls` plugins from [mason.nvim](https://github.com/williamboman/mason.nvim)
  - Supported plugins are,
    - `lombok`
    - `java-test`
    - `java-debug-adapter`
- Typed & documented APIs
- No callback hells I [promise](https://github.com/pyericz/promise-lua)

## How to Use

### Install the plugin

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

### Setup JDTLS like you would usually do

```lua
require('lspconfig').jdtls.setup({})
```

Yep! That's all :)

## Projects Acknowledgement

[nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) is a plugin that follows "Keep it simple, stupid!" approach.
If you love customizing things by yourself, then give nvim-jdtls a try.
