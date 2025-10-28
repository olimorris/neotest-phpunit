local M = {}

M.get_phpunit_cmd = function()
  return "vendor/bin/phpunit"
end

M.get_env = function()
  return {}
end

M.get_root_ignore_files = function()
  return {}
end

M.get_root_files = function()
  return { "composer.json", "phpunit.xml", ".gitignore" }
end

M.get_filter_dirs = function()
  return { ".git", "node_modules" }
end

M.get_docker_options = function()
  return {
    enabled = true,
    container = "php",
    args = {
      "exec",
      "-i",
    },
    workdir = nil,
  }
end

M.get_coverage_options = function()
  return {
    enabled = false,
    args = "--coverage-cobertura",
    path = "coverage/cobertura.xml",
  }
end

return M
