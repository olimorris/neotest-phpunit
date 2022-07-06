local logger = require("neotest.logging")

local M = {}
local separator = "::"

---Generate an id which we can use to match Treesitter queries and PHPUnit tests
---@param position neotest.Position The position to return an ID for
---@param namespace neotest.Position[] Any namespaces the position is within
---@return string
M.make_test_id = function(position)
  -- Treesitter starts line numbers from 0 so we add 1
  local id = position.path .. separator .. (tonumber(position.range[1]) + 1)

  logger.info("Path to test file:", { position.path })
  logger.info("Treesitter id:", { id })

  return id
end

---Pretty print a table
---@param tbl table
---@return string
function M.print_table(tbl)
  require("pl.pretty").dump(tbl)
end

---Recursively iterate through a deeply nested table to obtain certain keys
---@param data_table table
---@param key string
---@param output_table table
---@return table
M.iterate_over = function(data_table, key, output_table)
  if type(data_table) == "table" then
    for k, v in pairs(data_table) do
      if key == k then
        table.insert(output_table, v)
      end
      M.iterate_over(v, key, output_table)
    end
  end
  return output_table
end

---Extract the failure messages from the data
---@param data table
---@return boolean|table
local function errors_or_fails(data)
  local errors_fails = {}

  M.iterate_over(data, "error", errors_fails)
  M.iterate_over(data, "failure", errors_fails)

  if #errors_fails == 0 then
    return false
  end

  return errors_fails
end

---Make the outputs for a given test
---@param test table
---@param output_file string
---@return table
local function make_outputs(test, output_file)
  local test_attr = test["_attr"] or test[1]["_attr"]

  local test_id = test_attr.file .. separator .. test_attr.line
  logger.info("PHPUnit id:", { test_id })

  local test_output = {
    status = "passed",
    short = string.upper(test_attr.classname) .. "\n-> " .. "PASSED" .. " - " .. test_attr.name,
    output_file = output_file,
  }

  local test_fails = errors_or_fails(test)
  if test_fails then
    test_output.status = "failed"
    test_output.short = test_fails[1]["failure"] or test_fails[1]["errors"]
    test_output.errors = {
      {
        line = test_attr.line,
      },
    }
  end

  return test_id, test_output
end

---Get the test results from the parsed xml
---@param parsed_xml_output table
---@param output_file string
---@return neotest.Result[]
M.get_test_results = function(parsed_xml_output, output_file)
  local tests = {}
  local results = {}

  M.iterate_over(parsed_xml_output, "testcase", tests)

  -- File or Dir tests have nesting unlike single tests
  if #tests[1] > 0 then
    tests = tests[1]
  end

  for _, test in pairs(tests) do
    local test_id, test_output = make_outputs(test, output_file)
    results[test_id] = test_output
  end

  return results
end

return M
