local ok, async = pcall(require, "nio")
if not ok then
  async = require("neotest.async")
end

local lib = require("neotest.lib")
local logger = require("neotest.logging")
local utils = require("neotest-phpunit.utils")
local config = require("neotest-phpunit.config")

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

  for _, root_file in ipairs(config.get_root_files()) do
    result = lib.files.match_root_pattern(root_file)(dir)
    if result then
      break
    end
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
    if name == filter_dir then
      return false
    end
  end

  return true
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function NeotestAdapter.discover_positions(path)
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
  local spec_path = config.transform_spec_path(position.path)
  local results_path = config.results_path()

  local command = vim.tbl_flatten({
    config.get_phpunit_cmd(),
    position.name ~= "tests" and spec_path,
    "--log-junit=" .. results_path,
  })

  if position.type == "test" then
    local script_args = vim.tbl_flatten({
      "--filter",
      "::" .. position.name .. "( with data set .*)?$",
    })

    logger.info("spec_path:", { spec_path })
    logger.info("--filter position.name:", { position.name })

    command = vim.tbl_flatten({
      command,
      script_args,
    })
  end

  return {
    command = command,
    context = {
      results_path = results_path,
    },
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
    if is_callable(opts.transform_spec_path) then
      config.transform_spec_path = opts.transform_spec_path
    elseif opts.transform_spec_path then
      config.transform_spec_path = function()
        return opts.transform_spec_path
      end
    end
    if is_callable(opts.results_path) then
      config.results_path = opts.results_path
    elseif opts.results_path then
      config.results_path = function()
        return opts.results_path
      end
    end
    return NeotestAdapter
  end,
})

return NeotestAdapter
