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

---@class config.docker
---@field enabled boolean
---@field container_name string
---@field container_port string
---@field container_workdir string?
M.get_docker_options = function()
  return {
    enabled = false,
    container_name = "php",
    container_port = "9000",
    container_workdir = nil,
  }
end

---@class config.coverage
---@field enabled boolean
---@field args string
---@field path string
M.get_coverage_options = function()
  return {
    enabled = false,
    args = "--coverage-cobertura",
    path = "coverage/cobertura.xml",
  }
end

return M
