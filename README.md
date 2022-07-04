# neotest-phpunit

This plugin provides a [PHPUnit](https://phpunit.de) adapter for the [Neotest](https://github.com/nvim-neotest/neotest) framework.

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

_NOTE_: All usages of `lua require('neotest').run.run` can be mapped to a command in your config (this is not included and should be done by yourself).

#### Test single function

To test a single test, hover over the test and run `lua require('neotest').run.run()`

#### Test file

To test a file run `lua require('neotest').run.run(vim.fn.expand('%'))`

#### Test directory

To test a directory run `lua require('neotest').run.run("path/to/directory")`

#### Test suite

To test the full test suite run `lua require('neotest').run.run("path/to/root_project")`
e.g. `lua require('neotest').run.run(vim.fn.getcwd())`, presuming that vim's directory is the same as the project root.

## :gift: Contributing

This project is maintained by the Neovim PHP community. Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example spec that can be tested.

To trigger the tests for the adapter, run:

```sh
./scripts/test
```

## :clap: Thanks
A special thanks to the following contributers:

- [boonkerz](https://github.com/boonkerz)
