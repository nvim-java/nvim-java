# A Neovim Plugin Template

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/ellisonleao/nvim-plugin-template/default?style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template repository for Neovim plugins.

## Using it

Via `gh`:

```
$ gh repo create my-plugin -p ellisonleao/neovim-plugin-template
```

Via github web page:

Click on `Use this template`

![](https://docs.github.com/assets/cb-36544/images/help/repository/use-this-template-button.png)

## Features and structure

- 100% lua
- Github actions to run tests and formatting (Stylua)
- tests with busted and plenary.nvim

### Plugin structure

```
.
├── lua
│   └── module
│       └── init.lua
├── Makefile
├── plugin
│   └── module.lua
├── README.md
├── tests
│   ├── minimal_vim.vim
│   └── module
│       └── module_spec.lua
└── vendor
```
