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
  local test_attributes = testcase["_attr"]
  -- Treesitter starts line numbers from 0 so we subtract 1
  local test_id = test_attributes.file .. separator .. tonumber(test_attributes.line) - 1

  logger.info("PHPUnit id:", { test_id })

  local test = {
    status = "passed",
    short = string.upper(test_attributes.classname) .. "\n-> " .. "PASSED" .. " - " .. test_attributes.name,
    output_file = output_file,
  }

  if testcase["failure"] then
    test.status = "failed"
    test.short = testcase["failure"][1]
    test.errors = {
      {
        line = test_attributes.line,
      },
    }
  end

  return test_id, test
end

--- Parse PHPUnits XML output and return a table of test results
---@param parsed_xml_output table
---@param output_file string
---@return neotest.Result[]
M.parse_xml_output = function(parsed_xml_output, output_file)
  local tests = {}

  for _, testsuites in pairs(parsed_xml_output.testsuites) do
    if testsuites["_attr"].file then
      if testsuites.testcase["_attr"] then
        -- Single tests
        local test_id, test_output = generate_test_output(testsuites.testcase, output_file)
        tests[test_id] = test_output
      else
        -- File tests
        for _, testcase in pairs(testsuites.testcase) do
          local test_id, test_output = generate_test_output(testcase, output_file)
          tests[test_id] = test_output
        end
      end
    else
      -- Dir tests
      for _, testcase in pairs(testsuites.testsuite.testcase) do
        local test_id, test_output = generate_test_output(testcase, output_file)
        tests[test_id] = test_output
      end
    end
  end

  return tests
end

return M
