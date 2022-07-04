local logger = require("neotest.logging")

local M = {}
local separator = "::"

--- Generate an id which we can match between Treesitter and PHPUnit
---@param position neotest.Position The position to return an ID for
---@param namespace neotest.Position[] Any namespaces the position is within
---@return string
M.generate_treesitter_id = function(position)
  local id = position.path .. separator .. position.range[1]

  logger.info("Path to test file:", { position.path })
  logger.info("Treesitter id:", { id })

  return id
end

--- Produce the output of a single test that is exposed to Neotest
---@param testcase table
---@param output_file string
---@return table
local function generate_test_output(testcase, output_file)
  local test = {}
  local test_attr = testcase["_attr"]
  local test_id = test_attr.file .. separator .. tonumber(test_attr.line) - 1

  logger.info("PHPUnit id:", { test_id })

  test[test_id] = {
    status = "passed",
    short = string.upper(test_attr.classname) .. "\n-> " .. "PASSED" .. " - " .. test_attr.name,
    output_file = output_file,
  }

  if testcase["failure"] then
    test[test_id].status = "failed"
    test[test_id].short = testcase["failure"][1]
    test[test_id].errors = {
      {
        line = test_attr.line,
      },
    }
  end

  return test
end

--- Parse PHPUnits XML output and return a table of test results
---@param parsed_xml_output table
---@param output_file string
---@return neotest.Result[]
M.parse_xml_output = function(parsed_xml_output, output_file)
  local tests = {}

  for _, testsuites in pairs(parsed_xml_output.testsuites) do
    if testsuites.testcase["_attr"] then
      -- Single test
      return generate_test_output(testsuites.testcase, output_file)
    else
      -- Multple tests
      for _, testcase in pairs(testsuites.testcase) do
        table.insert(tests, generate_test_output(testcase, output_file))
      end
    end
  end
  return tests
end

return M
