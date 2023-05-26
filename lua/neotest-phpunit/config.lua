local M = {}

M.get_phpunit_cmd = function()
  return "vendor/bin/phpunit"
end

M.get_root_files = function()
  return {}
end

M.get_filter_dirs = function()
  return {}
end

return M
