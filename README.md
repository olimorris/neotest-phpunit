# neotest-phpunit

[![Tests](https://github.com/olimorris/neotest-phpunit/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/neotest-phpunit/actions/workflows/ci.yml)

This plugin provides a [PHPUnit](https://phpunit.de) adapter for the [Neotest](https://github.com/nvim-neotest/neotest) framework.

:warning: **This plugin is still in the early stages of development. Please test in anger against your existing PHPUnit tests** :warning:

## :package: Installation

Install the plugin using packer:

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    ...,
    'olimorris/neotest-phpunit',
  },
  config = function()
    require('neotest').setup({
      ...,
      adapters = {
        require('neotest-phpunit'),
      }
    })
  end
})
```

## :rocket: Usage

#### Test single method

To test a single test, hover over the test and run `lua require('neotest').run.run()`

#### Test file

To test a file run `lua require('neotest').run.run(vim.fn.expand('%'))`

#### Test directory

To test a directory run `lua require('neotest').run.run("path/to/directory")`

#### Test suite

To test the full test suite run `lua require('neotest').run.run({ suite = true })`

## :gift: Contributing

This project is maintained by the Neovim PHP community. Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example test that we can test against.

To trigger the tests for the adapter, run:

```sh
./scripts/test
```

## :clap: Thanks

A special thanks to the following contributers:

- [boonkerz](https://github.com/boonkerz)
