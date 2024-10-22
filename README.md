# :coffee: nvim-java

![Spring](https://img.shields.io/badge/Spring-6DB33F?style=for-the-badge&logo=spring&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Gradle](https://img.shields.io/badge/Gradle-02303A.svg?style=for-the-badge&logo=Gradle&logoColor=white)
![Apache Maven](https://img.shields.io/badge/Apache%20Maven-C71A36?style=for-the-badge&logo=Apache%20Maven&logoColor=white)
![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)

Just install and start writing `public static void main(String[] args)`.

> [!CAUTION]
> You cannot use `nvim-java` alongside `nvim-jdtls`. So remove `nvim-jdtls` before installing this

> [!TIP]
> You can find cool tips & tricks here https://github.com/nvim-java/nvim-java/wiki/Tips-&-Tricks

> [!NOTE]
> If you are facing errors while using, please check troubleshoot wiki https://github.com/nvim-java/nvim-java/wiki/Troubleshooting

## :loudspeaker: Demo

<https://github.com/nvim-java/nvim-java/assets/18459807/047c8c46-9a0a-4869-b342-d5c2e15647bc>

## :dizzy: Features

- :white_check_mark: Spring Boot Tools
- :white_check_mark: Diagnostics & Auto Completion
- :white_check_mark: Automatic Debug Configuration
- :white_check_mark: Organize Imports & Code Formatting
- :white_check_mark: Running Tests
- :white_check_mark: Run & Debug Profiles
- :white_check_mark: [Code Actions](https://github.com/nvim-java/nvim-java/wiki/Tips-&-Tricks#running-code-actions)

## :bulb: Why

- Everything necessary will be installed automatically
- Uses [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) to setup `jdtls`
- Realtime server settings updates is possible using [neoconf](https://github.com/folke/neoconf.nvim)
- Auto loads necessary `jdtls` plugins
  - Supported plugins are,
    - `spring-boot-tools`
    - `lombok`
    - `java-test`
    - `java-debug-adapter`

## :hammer: How to Install

<details>

<summary>:small_orange_diamond:details</summary>

### Starter Configs (Recommend for newbies)

Following are forks of original repositories pre-configured for java. If you
don't know how to get started, use one of the following to get started.
You can click on **n commits ahead of** link to see the changes made on top of the original project

- [LazyVim](https://github.com/nvim-java/starter-lazyvim)
- [Kickstart](https://github.com/nvim-java/starter-kickstart)
- [AstroNvim](https://github.com/nvim-java/starter-astronvim)

### Custom Configuration Instructions

- Install the plugin

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {'nvim-java/nvim-java'}
```

- Setup nvim-java before `lspconfig`

```lua
require('java').setup()
```

- Setup jdtls like you would usually do

```lua
require('lspconfig').jdtls.setup({})
```

Yep! That's all :)

</details>

## :keyboard: Commands

<details>

<summary>:small_orange_diamond:details</summary>

### Build

- `JavaBuildBuildWorkspace` - Runs a full workspace build

- `JavaBuildCleanWorkspace` - Clear the workspace cache
  (for now you have to close and reopen to restart the language server after
  the deletion)

### Runner

- `JavaRunnerRunMain` - Runs the application or selected main class (if there
  are multiple main classes)

```vim
:JavaRunnerRunMain
:JavaRunnerRunMain <arguments> <to> <pass>
```

- `JavaRunnerStopMain` - Stops the running application
- `JavaRunnerToggleLogs` - Toggle between show & hide runner log window

### DAP

- `JavaDapConfig` - DAP is autoconfigured on start up, but in case you want to
  force configure it again, you can use this API

### Test

- `JavaTestRunCurrentClass` - Run the test class in the active buffer
- `JavaTestDebugCurrentClass` - Debug the test class in the active buffer
- `JavaTestRunCurrentMethod` - Run the test method on the cursor
- `JavaTestDebugCurrentMethod` - Debug the test method on the cursor
- `JavaTestViewLastReport` - Open the last test report in a popup window

### Profiles

- `JavaProfile` - Opens the profiles UI

### Refactor

- `JavaRefactorExtractVariable` - Create a variable from value at cursor/selection
- `JavaRefactorExtractVariableAllOccurrence` - Create a variable for all
  occurrences from value at cursor/selection
- `JavaRefactorExtractConstant` - Create a constant from the value at cursor/selection
- `JavaRefactorExtractMethod` - Create a method from the value at cursor/selection
- `JavaRefactorExtractField` - Create a field from the value at cursor/selection

### Settings

- `JavaSettingsChangeRuntime` - Change the JDK version to another

</details>

## :computer: APIs

<details>

<summary>:small_orange_diamond:details</summary>

### Build

- `build.build_workspace` - Runs a full workspace build

```lua
require('java').build.build_workspace()
```

- `build.clean_workspace` - Clear the workspace cache
  (for now you have to close and reopen to restart the language server after
  the deletion)

```lua
require('java').build.clean_workspace()
```

### Runner

- `built_in.run_app` - Runs the application or selected main class (if there
  are multiple main classes)

```lua
require('java').runner.built_in.run_app({})
require('java').runner.built_in.run_app({'arguments', 'to', 'pass', 'to', 'main'})
```

- `built_in.stop_app` - Stops the running application

```lua
require('java').runner.built_in.stop_app()
```

- `built_in.toggle_logs` - Toggle between show & hide runner log window

```lua
require('java').runner.built_in.toggle_logs()
```

### DAP

- `config_dap` - DAP is autoconfigured on start up, but in case you want to force
  configure it again, you can use this API

```lua
require('java').dap.config_dap()
```

### Test

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
require('java').test.view_last_report()
```

### Profiles

```lua
require('java').profile.ui()
```

### Refactor

- `extract_variable` - Create a variable from value at cursor/selection

```lua
require('java').refactor.extract_variable()
```

- `extract_variable_all_occurrence` - Create a variable for all occurrences from
  value at cursor/selection

```lua
require('java').refactor.extract_variable_all_occurrence()
```

- `extract_constant` - Create a constant from the value at cursor/selection

```lua
require('java').refactor.extract_constant()
```

- `extract_method` - Create method from the value at cursor/selection

```lua
require('java').refactor.extract_method()
```

- `extract_field` - Create a field from the value at cursor/selection

```lua
require('java').refactor.extract_field()
```

### Settings

- `change_runtime` - Change the JDK version to another

```lua
require('java').settings.change_runtime()
```

</details>

## :clamp: How to Use JDK X.X Version?

<details>
  
<summary>:small_orange_diamond:details</summary>

### Method 1

[Neoconf](https://github.com/folke/neoconf.nvim) can be used to manage LSP
setting including jdtls. Neoconf allows global configuration as well as project
vice configurations. Here is how you can set Jdtls setting on `neoconf.json`

```json
{
  "lspconfig": {
    "jdtls": {
      "java.configuration.runtimes": [
        {
          "name": "JavaSE-21",
          "path": "/opt/jdk-21",
          "default": true
        }
      ]
    }
  }
}
```

### Method 2

Pass the settings to Jdtls setup.

```lua
require('lspconfig').jdtls.setup({
  settings = {
    java = {
      configuration = {
        runtimes = {
          {
            name = "JavaSE-21",
            path = "/opt/jdk-21",
            default = true,
          }
        }
      }
    }
  }
})
```

</details>

## :wrench: Configuration

<details>

<summary>:small_orange_diamond:details</summary>

For most users changing the default configuration is not necessary. But if you
want, following options are available

```lua
{
  --  list of file that exists in root of the project
  root_markers = {
    'settings.gradle',
    'settings.gradle.kts',
    'pom.xml',
    'build.gradle',
    'mvnw',
    'gradlew',
    'build.gradle',
    'build.gradle.kts',
    '.git',
  },

  -- load java test plugins
  java_test = {
    enable = true,
  },

  -- load java debugger plugins
  java_debug_adapter = {
    enable = true,
  },

  spring_boot_tools = {
    enable = true,
  },

  jdk = {
    -- install jdk using mason.nvim
    auto_install = true,
  },

  notifications = {
    -- enable 'Configuring DAP' & 'DAP configured' messages on start up
    dap = true,
  },

  -- We do multiple verifications to make sure things are in place to run this
  -- plugin
  verification = {
    -- nvim-java checks for the order of execution of following
    -- * require('java').setup()
    -- * require('lspconfig').jdtls.setup()
    -- IF they are not executed in the correct order, you will see a error
    -- notification.
    -- Set following to false to disable the notification if you know what you
    -- are doing
    invalid_order = true,

    -- nvim-java checks if the require('java').setup() is called multiple
    -- times.
    -- IF there are multiple setup calls are executed, an error will be shown
    -- Set following property value to false to disable the notification if
    -- you know what you are doing
    duplicate_setup_calls = true,

    -- nvim-java checks if nvim-java/mason-registry is added correctly to
    -- mason.nvim plugin.
    -- IF it's not registered correctly, an error will be thrown and nvim-java
    -- will stop setup
    invalid_mason_registry = true,
  },
}
```

</details>

## :golf: Architecture

<details>

<summary>:small_orange_diamond:details</summary>

Following is the high level idea. Jdtls is the language server nvim-java
communicates with. However, we don't have all the features we need just in
Jdtls. So, we are loading java-test & java-debug-adapter extensions when we
launch Jdtls. Once the language server is started, we communicate with the
language server to do stuff.

For instance, to run the current test,

- Request Jdtls for test classes
- Request Jdtls for class paths, module paths, java executable
- Request Jdtls to start a debug session and send the port of the session back
- Prepare TCP connections to listen to the test results
- Start nvim-dap and let user interactions to be handled by nvim-dap
- Parse the test results as they come in
- Once the execution is done, open a window show the test results

```text
  ┌────────────┐                         ┌────────────┐
  │            │                         │            │
  │   Neovim   │                         │   VSCode   │
  │            │                         │            │
  └─────▲──────┘                         └──────▲─────┘
        │                                       │
        │                                       │
        │                                       │
        │                                       │
┌───────▼───────┐                ┌──────────────▼──────────────┐
│               │                │                             │
│   nvim-java   │                │   Extension Pack for Java   │
│               │                │                             │
└───────▲───────┘                └──────────────▲──────────────┘
        │                                       │
        │                                       │
        │                                       │
        │                                       │
        │                                       │
        │              ┌───────────┐            │
        │              │           │            │
        └──────────────►   JDTLS   ◄────────────┘
                       │           │
                       └───▲───▲───┘
                           │   │
                           │   │
                           │   │
                           │   │
                           │   │
  ┌───────────────┐        │   │         ┌────────────────────────┐
  │               │        │   │         │                        │
  │   java-test   ◄────────┘   └─────────►   java-debug-adapter   │
  │               │                      │                        │
  └───────────────┘                      └────────────────────────┘
```

</details>

## :bookmark_tabs: Projects Acknowledgement

- [spring-boot.nvim](https://github.com/JavaHello/spring-boot.nvim) is the one
  that starts sts4 & do other necessary `jdtls` `sts4` sync command registration
  in `nvim-java`.

- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) is a plugin that follows
  "Keep it simple, stupid!" approach. If you love customizing things by yourself,
  then give nvim-jdtls a try.

> [!WARNING]
> You cannot use `nvim-java` alongside `nvim-jdtls`. So remove `nvim-jdtls`
> before installing this
