local logger = require("neotest.logging")
local uv = vim.loop

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

---Recursively iterate through a deeply nested table to obtain specified keys
---@param data_table table
---@param key string
---@param output_table table
---@return table
local function iterate_key(data_table, key, output_table)
  if type(data_table) == "table" then
    for k, v in pairs(data_table) do
      if key == k then
        table.insert(output_table, v)
      end
      iterate_key(v, key, output_table)
    end
  end
  return output_table
end

---Extract the failure messages from the tests
---@param tests table,
---@return boolean|table
local function errors_or_fails(tests)
  local errors_fails = {}

  iterate_key(tests, "error", errors_fails)
  iterate_key(tests, "failure", errors_fails)

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

  local test_failed = errors_or_fails(test)
  if test_failed then
    test_output.status = "failed"
    test_output.short = test_failed[1]["failure"] or test_failed[1]["errors"]
    test_output.errors = {
      {
        line = test_attr.line,
      },
    }
  end

  return test_id, test_output
end

---Iterate through test results and create a table of test IDs and outputs
---@param tests table
---@param output_file string
---@param output_table table
---@return table
local function iterate_test_outputs(tests, output_file, output_table)
  for i = 1, #tests, 1 do
    if #tests[i] == 0 then
      local test_id, test_output = make_outputs(tests[i], output_file)
      output_table[test_id] = test_output
    else
      iterate_test_outputs(tests[i], output_file, output_table)
    end
  end
  return output_table
end

---Get the test results from the parsed xml
---@param parsed_xml_output table
---@param output_file string
---@return neotest.Result[]
M.get_test_results = function(parsed_xml_output, output_file)
  local tests = iterate_key(parsed_xml_output, "testcase", {})
  return iterate_test_outputs(tests, output_file, {})
end

local is_windows = uv.os_uname().version:match("Windows")

local function is_fs_root(path)
  if is_windows then
    return path:match("^%a:$")
  else
    return path == "/"
  end
end

local function dirname(path)
  local strip_dir_pat = "/([^/]+)$"
  local strip_sep_pat = "/$"
  if not path or #path == 0 then
    return
  end
  local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
  if #result == 0 then
    if is_windows then
      return path:sub(1, 2):upper()
    else
      return "/"
    end
  end
  return result
end

local function iterate_parents(path)
  local function it(_, v)
    if v and not is_fs_root(v) then
      v = dirname(v)
    else
      return
    end
    if v and uv.fs_realpath(v) then
      return v, path
    else
      return
    end
  end
  return it, path, path
end

function M.search_ancestors(startpath, func)
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

local function exists(filename)
  local stat = uv.fs_stat(filename)
  return stat and stat.type or false
end

function M.find_node_modules_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    local joined = table.concat(vim.tbl_flatten({path, "vendor"}), "/");
    if exists(joined) == "directory" then
      return path
    end
  end)
end

return M
