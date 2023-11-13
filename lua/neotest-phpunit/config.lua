local M = {}

M.get_phpunit_cmd = function()
  return "vendor/bin/phpunit"
end

M.get_env = function()
  return {}
end

M.get_root_files = function()
  return { "composer.json", "phpunit.xml", ".gitignore" }
end

M.get_filter_dirs = function()
  return { ".git", "node_modules" }
end

return M
