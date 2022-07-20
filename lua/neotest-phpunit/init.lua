local lib = require("neotest.lib")
local async = require("neotest.async")
local logger = require("neotest.logging")
local utils = require("neotest-phpunit.utils")

---@class neotest.Adapter
---@field name string
local NeotestAdapter = { name = "neotest-phpunit" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
NeotestAdapter.root = lib.files.match_root_pattern("composer.json", "phpunit.xml")

---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path)
  if string.match(file_path, "vendor/") or not string.match(file_path, "tests/") then
    return false
  end
  return vim.endswith(file_path, "Test.php")
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
    position_id = utils.make_test_id,
  })
end

---@param args neotest.RunArgs
---@return neotest.RunSpec | nil
function NeotestAdapter.build_spec(args)
  local position = args.tree:data()
  local results_path = async.fn.tempname()

  local binary = "phpunit"

  local cwd = nil;

  -- If we can find a closer phpunit executable we can use that.
  local relativeBinaryPath = utils.find_node_modules_ancestor(position.path) .. "/vendor/bin/phpunit";
  if vim.fn.filereadable(relativeBinaryPath) then
    -- We need to make sure it runs from the working directory so it picks up the correct phpunit config.
    cwd = utils.find_node_modules_ancestor(position.path);
    binary = relativeBinaryPath
  elseif vim.fn.filereadable("vendor/bin/phpunit") then
    binary = "vendor/bin/phpunit"
  end

  local command = vim.tbl_flatten({
    binary,
    position.name ~= "tests" and position.path,
    "--log-junit=" .. results_path,
  })

  if position.type == "test" then
    local script_args = vim.tbl_flatten({
      "--filter",
      position.name,
    })

    command = vim.tbl_flatten({
      command,
      script_args,
    })
  end

  return {
    cwd = cwd,
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

setmetatable(NeotestAdapter, {
  __call = function()
    return NeotestAdapter
  end,
})

return NeotestAdapter
