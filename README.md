# neotest-phpunit

[![Tests](https://github.com/olimorris/neotest-phpunit/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/neotest-phpunit/actions/workflows/ci.yml)

This plugin provides a [PHPUnit](https://phpunit.de) adapter for the [Neotest](https://github.com/nvim-neotest/neotest) framework.

<img width="1502" alt="Neotest and PHPUnit" src="https://user-images.githubusercontent.com/9512444/177888651-c55f8613-686a-40d0-8753-ca802ee6c000.png">

## :package: Installation

Install with the package manager of your choice:

**Lazy**

```lua
{
  "nvim-neotest/neotest",
  lazy = true,
  dependencies = {
    ...,
    "olimorris/neotest-phpunit",
  },
  config = function()
    require("neotest").setup({
      ...,
      adapters = {
        require("neotest-phpunit")
      },
    }
  end
}
```

**Packer**

```lua
use({
  "nvim-neotest/neotest",
  requires = {
    ...,
    "olimorris/neotest-phpunit",
  },
  config = function()
    require("neotest").setup({
      ...,
      adapters = {
        require("neotest-phpunit"),
      }
    })
  end
})
```

## :wrench: Configuration

### Default configuration

> [!NOTE]
> You only need to the call the `setup` function if you wish to change any of the defaults.

<details>
  <summary>Click to see the default configuration</summary>

```lua
adapters = {
  require("neotest-phpunit")({
    phpunit_cmd = function()
      return "vendor/bin/phpunit" -- for `dap` strategy then it must return string (table values will cause validation error)
    end,
    root_files = { "composer.json", "phpunit.xml", ".gitignore" },
    filter_dirs = { ".git", "node_modules" },
    env = {}, -- for example {XDEBUG_CONFIG = 'idekey=neotest'}
    dap = nil, -- to configure `dap` strategy put single element from `dap.configurations.php`
  }),
}
```

</details>

### The test command

The command used to run tests can be changed via the `phpunit_cmd` option:

```lua
require("neotest-phpunit")({
  phpunit_cmd = function()
    return "vendor/bin/phpunit"
  end
})
```

### Setting the root directory

For Neotest adapters to work, they need to define a project root whereby the process of discovering tests can take place. By default, the adapter looks for a `composer.json`, `phpunit.xml` or `.gitignore` file. These can be changed with:

```lua
require("neotest-phpunit")({
  root_files = { "README.md" }
})
```

You can even set `root_files` with a function which returns a table:

```lua
require("neotest-phpunit")({
  root_files = function() return { "README.md" } end
})
```

If there are projects you don't want discovered, you can instead set `root_ignore_files` to ignore any matching projects.

For example, if your project uses Pest and the appropriate [neotest adapter](https://github.com/V13Axel/neotest-pest), you'll need to set:

```lua
require("neotest-phpunit")({
    root_ignore_files = { "tests/Pest.php" }
})
```

### Filtering directories

By default, the adapter will search test files in all dirs in the root with the exception of `node_modules` and `.git`. You can change this with:

```lua
require("neotest-phpunit")({
  filter_dirs = { "vendor" }
})
```

You can even set `filter_dirs` with a function which returns a table:

```lua
require("neotest-phpunit")({
  filter_dirs = function() return { "vendor" } end
})
```

### Debugging

The plugin can also be used for debugging via a dap strategy.

Firstly, install and configure [nvim-dap](https://github.com/mfussenegger/nvim-dap) with [vscode-php-debug](https://github.com/xdebug/vscode-php-debug). Then set the following dap configuration:

```lua
dap.configurations.php = {
  {
    log = true,
    type = "php",
    request = "launch",
    name = "Listen for XDebug",
    port = 9003,
    stopOnEntry = false,
    xdebugSettings = {
      max_children = 512,
      max_data = 1024,
      max_depth = 4,
    },
    breakpoints = {
      exception = {
        Notice = false,
        Warning = false,
        Error = false,
        Exception = false,
        ["*"] = false,
      },
    },
  }
}
```

Then in the plugin's config, add:

```lua
require("neotest-phpunit")({
  env = {
      XDEBUG_CONFIG = "idekey=neotest",
  },
  dap = dap.configurations.php[1],
})
```

> [!NOTE]
> If you run a test with the `dap` strategy from the summary window (by default by `d`) and see that the window content has been replaced by debugger content then consider setting `dap.defaults.fallback.switchbuf = "useopen"` or Neovim level [`switchbuf`](https://neovim.io/doc/user/options.html#'switchbuf')

## :rocket: Usage

#### Test single method

To test a single test, hover over the test and run `lua require("neotest").run.run()`

#### Test file

To test a file run `lua require("neotest").run.run(vim.fn.expand("%"))`

#### Test directory

To test a directory run `lua require("neotest").run.run("path/to/directory")`

#### Test suite

To test the full test suite run `lua require("neotest").run.run({ suite = true })`

## :gift: Contributing

This project is maintained by the Neovim PHP community. Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example test that we can test against.

To trigger the tests for the adapter, run:

```sh
./scripts/test
```

