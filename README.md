# neotest-phpunit

[![Tests](https://github.com/olimorris/neotest-phpunit/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/neotest-phpunit/actions/workflows/ci.yml)

This plugin provides a [PHPUnit](https://phpunit.de) adapter for the [Neotest](https://github.com/nvim-neotest/neotest) framework.

<img width="1502" alt="Neotest and PHPUnit" src="https://user-images.githubusercontent.com/9512444/177888651-c55f8613-686a-40d0-8753-ca802ee6c000.png">

:warning: _This plugin is still in the early stages of development. Please test against your PHPUnit tests_ :warning:

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

> **Note**: You only need to the call the `setup` function if you wish to change any of the defaults.

<details>
  <summary>Click to see the default configuration</summary>

```lua
adapters = {
  require("neotest-phpunit")({
    phpunit_cmd = function()
      return "vendor/bin/phpunit"
    end,
    root_files = { "composer.json", "phpunit.xml", ".gitignore" },
    filter_dirs = { ".git", "node_modules" }
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

For Neotest adapters to work, they need to define a project root whereby the process of discovering tests can take place. By default, the adapter looks for a `composer.json`, `phpunit.xml` or `.gitignore` file. These can be added to with:

```lua
require("neotest-phpunit")({
  root_files = { "README.md" }
})
```

### Filtering directories

By default, the adapter will search test files in all dirs in the root with the exception of `node_modules` and `.git`. In a big project, this may result in slow performance. You can also add additional directories to filter out:

```lua
require("neotest-phpunit")({
  filter_dirs = { "vendor" }
})
```

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

