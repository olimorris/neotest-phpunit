-- TODO: Invalidate cache when daemon or php container is stopped

local logger = require("neotest.logging")
local lib = require("neotest.lib")

---@class Docker
local Docker = {}

---@private
Docker.cmd = "docker"

---@private
Docker.files = {
  "Dockerfile",
  "docker-compose.yaml",
  "docker-compose.yml",
  "compose.yaml",
  "compose.yml",
}

---@private
Docker.cache = {}

---Checks if docker daemon is running
function Docker.is_daemon_running()
  if Docker.cache.is_daemon_running then
    return Docker.cache.is_daemon_running
  end

  local is_daemon_running = vim.system({ Docker.cmd, "version", "--format", "{{.Server.Version}}" }):wait()

  Docker.cache.is_daemon_running = is_daemon_running.code == 0

  return Docker.cache.is_daemon_running
end

---Tries to resolve root path
---@private
Docker.get_root_path = function()
  if Docker.cache.root then
    return Docker.cache.root
  end

  for _, dockerfile in ipairs(Docker.files) do
    local path = lib.files.match_root_pattern(dockerfile)(vim.fn.getcwd())
    if path then
      Docker.cache.root = path

      return Docker.cache.root
    end
  end
end

---@private
Docker.root_path = Docker.get_root_path()

---Find container's id
---@param filter? "name"|"publish"
---@param value? string
---@return string?
function Docker.get_container_id(filter, value)
  if Docker.cache.container_id then
    logger.debug("Docker container id is cached. [" .. Docker.cache.container_id .. "]")
    return Docker.cache.container_id
  end

  if filter and value then
    local container_id =
      vim.trim(vim.system({ Docker.cmd, "ps", "-q", "--filter", filter .. "=" .. value }):wait().stdout)

    if container_id == "" then
      logger.info("No running container with " .. filter .. ": " .. value)

      return
    end

    Docker.cache.container_id = container_id

    return Docker.cache.container_id
  end
end

---Returns container's workdir
---@return string
function Docker.get_container_workdir()
  if Docker.cache.container_workdir then
    logger.debug(
      "Docker container workdir for container with id "
        .. Docker.cache.container_id
        .. " is cached. ["
        .. Docker.cache.container_workdir
        .. "]"
    )
    return Docker.cache.container_workdir
  end

  local container_workdir = vim.trim(
    vim.system({ Docker.cmd, "inspect", "--format", "{{.Config.WorkingDir}}", Docker.cache.container_id }):wait().stdout
  )

  if container_workdir == "" then
    logger.info("No workdir for container with id: " .. Docker.cache.container_id)
  end

  Docker.cache.container_workdir = container_workdir

  return Docker.cache.container_workdir
end

---Returns container's shell path
---@return string
function Docker.get_container_shell()
  if Docker.cache.container_shell then
    logger.debug(
      "Docker container shell for container with id "
        .. Docker.cache.container_id
        .. " is cached. ["
        .. Docker.cache.container_shell
        .. "]"
    )
    return Docker.cache.container_shell
  end

  local container_shell = vim.trim(vim
    .system({
      Docker.cmd,
      "exec",
      "-i",
      Docker.cache.container_id,
      "/bin/sh",
      "-c",
      "if [ -f /bin/sh ]; then echo /bin/sh; else echo /bin/bash; fi | tr -d '\r'",
    })
    :wait().stdout)

  if container_shell == "" then
    logger.info("Shell path not found for container with id: " .. Docker.cache.container_id)
  end

  Docker.cache.container_shell = container_shell

  return Docker.cache.container_shell
end

---Transform path to use workdir as cwd
---@param host_path string
---@return string
function Docker.translate_path_to_container(host_path)
  if vim.startswith(host_path, Docker.root_path) then
    local relative_path = host_path:sub(#Docker.root_path + 2)
    return Docker.get_container_workdir() .. "/" .. relative_path
  end

  return host_path
end

---Builds the script arguments for running PHPUnit inside a docker container
---@param args {env: table<string, string>, phpunit_cmd: string, script_args: string[]}
---@return string
function Docker.build_script_args(args)
  -- INFO: Prepend all env variables
  local result = vim
    .iter(args.env)
    :map(function(k, v)
      return k .. "=" .. v
    end)
    :totable()

  table.insert(result, args.phpunit_cmd)
  table.insert(result, Docker.translate_path_to_container(table.concat(args.script_args, " ")))

  return table.concat(result, " ")
end

---Builds a DAP configuration for debugging PHPUnit tests inside a Docker container
---@param dap_strategy table
---@param args {phpunit_cmd: string, script_args: string[]}
---@return table
function Docker.dap_config(dap_strategy, args)
  local dap_config = vim.deepcopy(dap_strategy)

  dap_config.program = args.phpunit_cmd
  dap_config.args = vim.split(Docker.translate_path_to_container(table.concat(args.script_args, " ")), " ")
  dap_config.runtimeExecutable = Docker.cmd
  dap_config.runtimeArgs = {
    "exec",
    "-w",
    Docker.get_container_workdir(),
    Docker.get_container_id(),
    "php",
    "-dxdebug.mode=debug",
    "-dxdebug.discover_client_host=1",
    "-dxdebug.client_host=host.docker.internal",
    "-dxdebug.client_port=9003",
    "-dxdebug.start_with_request=yes",
    "-dxdebug.idekey=neovim",
  }

  return dap_config
end

---Setup phpunit command to execute tests in docker
---@param args {env: table<string, string>, phpunit_cmd: string, script_args: string[]}
---@param docker_config config.docker
---@return string[]|nil
function Docker.build_cmd(args, docker_config)
  if not Docker.is_daemon_running() then
    return
  end

  local container_id = Docker.get_container_id("name", docker_config.container_name)
    or Docker.get_container_id("publish", docker_config.container_port)

  if not container_id then
    logger.error("Couldn't find container's id")
    return
  end

  local container_workdir = Docker.get_container_workdir()
  local container_shell = Docker.get_container_shell()

  local script = Docker.build_script_args({
    env = args.env,
    phpunit_cmd = args.phpunit_cmd,
    script_args = args.script_args,
  })

  local docker_cmd =
    { Docker.cmd, "exec", "-i", { "-w", container_workdir }, container_id, container_shell, "-c", script }

  return vim.iter(docker_cmd):flatten():totable()
end

---Copy test results to host machine
---@param output_path string
function Docker.copy_to_host(output_path)
  vim.system({ Docker.cmd, "cp", "-a", Docker.get_container_id() .. ":" .. output_path, output_path }):wait()
  vim
    .system({
      "sed",
      "-i",
      "_",
      "s#" .. Docker.get_container_workdir() .. "#" .. Docker.root_path .. "#g",
      output_path,
    })
    :wait()
end

return Docker
