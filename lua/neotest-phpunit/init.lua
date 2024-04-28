local ok, async = pcall(require, "nio")
if not ok then
  async = require("neotest.async")
end

local lib = require("neotest.lib")
local logger = require("neotest.logging")
local utils = require("neotest-phpunit.utils")
local config = require("neotest-phpunit.config")

local dap_configuration

local function get_strategy_config(strategy, program, args)
  local cfg = {
    dap = function()
      vim.validate({ dap = {
        dap_configuration,
        function (val)
          local valid = type(val) == "table" and not vim.tbl_isempty(val)

          return valid, "Configure `dap` field (like in dap.configurations.php) before using this strategy"
        end,
        "not empty table"
      }})
      vim.validate({
        phpunit_cmd = {
          program,
          function (val)
            return type(val) == "string", "For `dap` strategy `phpunit_cmd` must be (or return) string."
          end,
          "string",
        }
      })

      return vim.tbl_extend("keep", {
        type = "php",
        name = "Neotest Debugger",
        cwd = async.fn.getcwd(),
        program = program,
        args = args,
        runtimeArgs = { "-dzend_extension=xdebug.so" },
      }, dap_configuration or {})
    end,
  }
  if cfg[strategy] then
    return cfg[strategy]()
  end
end

---@class neotest.Adapter
---@field name string
local NeotestAdapter = { name = "neotest-phpunit" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function NeotestAdapter.root(dir)
  local result = nil

  for _, root_ignore_file in ipairs(config.get_root_ignore_files()) do
    result = lib.files.match_root_pattern(root_ignore_file)(dir)
    if result then return nil end
  end

  for _, root_file in ipairs(config.get_root_files()) do
    result = lib.files.match_root_pattern(root_file)(dir)
    if result then break end
  end

  return result
end

---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path)
  return vim.endswith(file_path, "Test.php")
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@return boolean
function NeotestAdapter.filter_dir(name)
  for _, filter_dir in ipairs(config.get_filter_dirs()) do
    if name == filter_dir then return false end
  end

  return true
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function NeotestAdapter.discover_positions(path)
  if not NeotestAdapter.is_test_file(path) then
    return nil
  end

  local query = [[
    ((class_declaration
      name: (name) @namespace.name (#match? @namespace.name "Test")
    )) @namespace.definition

    ((method_declaration
      (name) @test.name (#match? @test.name "test")
    )) @test.definition

    (((comment) @test_comment (#match? @test_comment "\\@test") .
      (method_declaration
        (name) @test.name
      ) @test.definition
    ))
  ]]

  return lib.treesitter.parse_positions(path, query, {
    position_id = "require('neotest-phpunit.utils').make_test_id",
  })
end


---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function NeotestAdapter.build_spec(args)
  local position = args.tree:data()
  local results_path = async.fn.tempname()
  local program = config.get_phpunit_cmd()

  local script_args = {
    position.name ~= "tests" and position.path,
    "--log-junit=" .. results_path,
  }

  if position.type == "test" then
    local filter_args = vim.tbl_flatten({
      "--filter",
      '::' .. position.name .. '( with data set .*)?$',
    })

    logger.info("position.path:", { position.path })
    logger.info("--filter position.name:", { position.name })

    script_args = vim.tbl_flatten({
      script_args,
      filter_args,
    })
  end

  local command = vim.tbl_flatten({
    program,
    script_args,
  })

  ---@type neotest.RunSpec
  return {
    command = command,
    context = {
      results_path = results_path,
    },
    strategy = get_strategy_config(args.strategy, program, script_args),
    env = args.env or config.get_env(),
  }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return neotest.Result[]
function NeotestAdapter.results(test, result, tree)
  local output_file = test.context.results_path

  local ok, data = pcall(lib.files.read, output_file)
  if not ok then
    logger.error("No test output file found:", output_file)
    return {}
  end

  local ok, parsed_data = pcall(lib.xml.parse, data)
  if not ok then
    logger.error("Failed to parse test output:", output_file)
    return {}
  end

  local ok, results = pcall(utils.get_test_results, parsed_data, output_file)
  if not ok then
    logger.error("Could not get test results", output_file)
    return {}
  end

  return results
end

local is_callable = function(obj)
  return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

setmetatable(NeotestAdapter, {
  __call = function(_, opts)
    if is_callable(opts.phpunit_cmd) then
      config.get_phpunit_cmd = opts.phpunit_cmd
    elseif opts.phpunit_cmd then
      config.get_phpunit_cmd = function()
        return opts.phpunit_cmd
      end
    end
    if is_callable(opts.root_ignore_files) then
      config.get_root_ignore_files = opts.root_ignore_files
    elseif opts.root_ignore_files then
      config.get_root_ignore_files = function()
        return opts.root_ignore_files
      end
    end
    if is_callable(opts.root_files) then
      config.get_root_files = opts.root_files
    elseif opts.root_files then
      config.get_root_files = function()
        return opts.root_files
      end
    end
    if is_callable(opts.filter_dirs) then
      config.get_filter_dirs = opts.filter_dirs
    elseif opts.filter_dirs then
      config.get_filter_dirs = function()
        return opts.filter_dirs
      end
    end
    if is_callable(opts.env) then
      config.get_env = opts.env
    elseif type(opts.env) == "table" then
      config.get_env = function ()
        return opts.env
      end
    end
    if type(opts.dap) == "table" then
      dap_configuration = opts.dap
    end
    return NeotestAdapter
  end,
})

return NeotestAdapter
