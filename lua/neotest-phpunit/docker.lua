local Job = require("plenary.job")
local lib = require("neotest.lib")
local logger = require("neotest.logging")

local M = {}

local docker_files = {
  "Dockerfile",
  "docker-compose.yaml",
  "docker-compose.yml",
  "compose.yaml",
  "compose.yml",
}

local docker_cmd = "docker"

local job_result_ok = function(job)
  local ok, res = pcall(function()
    job:sync(3000)
    return job:result()
  end)
  return ok and res and res[1] or nil
end

M.cache = {
  daemon = nil,
  root = nil,
  container = nil,
  workdir = nil,
  shell = nil,
  phpunit = nil,
}

M.daemon_is_running = function()
  if M.cache.daemon then
    logger.debug("Using cached Docker running state: " .. tostring(M.cache.daemon))
    return M.cache.daemon
  end

  local job = Job:new({
    command = docker_cmd,
    args = { "ps" },
  })

  local ok, code = pcall(function()
    job:sync(3000)
    return job.code
  end)

  M.cache.daemon = ok and code == 0

  return M.cache.daemon
end

M.get_root_path = function()
  if M.cache.root then
    return M.cache.root
  end

  for _, dockerfile in ipairs(docker_files) do
    local path = lib.files.match_root_pattern(dockerfile)(vim.fn.getcwd())
    if path then
      M.cache.root = path

      return M.cache.root
    end
  end
end

M.root_path = M.get_root_path()

M.get_container_id = function(name)
  if M.cache.container then
    return M.cache.container
  end

  local job = Job:new({
    command = docker_cmd,
    args = { "ps", "-q", "--filter", "name=" .. name },
  })

  local id = job_result_ok(job)

  if not id or id == "" then
    logger.error("No running container found with name: " .. name)
    return nil
  end

  M.cache.container = id
  return M.cache.container
end

M.get_working_dir = function(container_id)
  if M.cache.workdir then
    return M.cache.workdir
  end

  local job = Job:new({
    command = docker_cmd,
    args = { "inspect", "--format", "{{.Config.WorkingDir}}", container_id },
  })

  local dir = job_result_ok(job)

  if dir then
    M.cache.workdir = dir
  end

  return M.cache.workdir
end

M.get_shell_path = function(container_id)
  if M.cache.shell then
    return M.cache.shell
  end

  local job = Job:new({
    command = docker_cmd,
    args = {
      "exec",
      "-i",
      container_id,
      "/bin/sh",
      "-c",
      "if [ -f /bin/sh ]; then echo /bin/sh; else echo /bin/bash; fi | tr -d '\r'",
    },
  })

  local shell = job_result_ok(job)

  if shell then
    M.cache.shell = shell
  end

  return M.cache.shell
end

M.get_phpunit_path = function(container_id, shell_path, config_phpunit_cmd)
  if M.cache.phpunit then
    return M.cache.phpunit
  end

  local default_phpunit_cmd = config_phpunit_cmd or "bin/phpunit"

  local job = Job:new({
    command = docker_cmd,
    args = {
      "exec",
      "-i",
      container_id,
      shell_path,
      "-c",
      string.format(
        "if [ -f vendor/bin/phpunit ]; then echo vendor/bin/phpunit; else echo %s; fi | tr -d '\r'",
        default_phpunit_cmd
      ),
    },
  })

  local phpunit_path = job_result_ok(job)

  if phpunit_path then
    M.cache.phpunit = phpunit_path
  end

  return M.cache.phpunit
end

M.translate_path_to_container = function(host_path, docker_workdir_path)
  if vim.startswith(host_path, M.root_path) then
    local relative_path = host_path:sub(#M.root_path + 2)
    return docker_workdir_path .. "/" .. relative_path
  end

  return host_path
end

M.build_script_args = function(args, coverage_config)
  local result = {}

  for k, v in pairs(args.env) do
    local s = k .. "=" .. v
    table.insert(result, s)
  end

  table.insert(result, args.phpunit)
  table.insert(result, M.translate_path_to_container(table.concat(args.script_args, " "), args.docker_workdir))

  if coverage_config.enabled then
    table.insert(result, coverage_config.args .. " /tmp/coverage.xml")
  end

  return table.concat(result, " ")
end

M.patch_dap_config = function(dap_config, args)
  dap_config.program = args.phpunit_path
  dap_config.args =
    vim.split(M.translate_path_to_container(table.concat(args.phpunit_args, " "), args.docker_workdir), " ")
  dap_config.runtimeExecutable = docker_cmd
  dap_config.runtimeArgs = {
    "exec",
    "-w",
    args.docker_workdir,
    args.container_id,
    "php",
    "-dxdebug.mode=debug",
    "-dxdebug.discover_client_host=1",
    "-dxdebug.client_host=host.docker.internal",
    "-dxdebug.client_port=9003",
    "-dxdebug.start_with_request=yes",
    "-dxdebug.idekey=neovim",
  }
end

M.get_docker_cmd = function(args, config, coverage, dap_config)
  local container_id = M.get_container_id(config.container)
  local shell_path = M.get_shell_path(container_id)
  local phpunit_path = M.get_phpunit_path(container_id, shell_path)
  local docker_workdir_path = config.workdir or M.get_working_dir(container_id)

  local script = M.build_script_args({
    phpunit = phpunit_path,
    env = args.env,
    script_args = args.script_args,
    docker_workdir = docker_workdir_path,
  }, coverage)

  local docker_exec_cmd =
    { docker_cmd, "exec", "-i", { "-w", docker_workdir_path }, container_id, shell_path, "-c", script }

  if dap_config then
    M.patch_dap_config(dap_config, {
      phpunit_path = phpunit_path,
      phpunit_args = args.script_args,
      container_id = container_id,
      docker_workdir = docker_workdir_path,
    })
  end

  return vim.iter(docker_exec_cmd):flatten():totable()
end

M.copy_to_host = function(output_path, container_name, coverage_config)
  local container_id = M.get_container_id(container_name)

  Job:new({
    command = docker_cmd,
    args = { "cp", "-a", container_id .. ":" .. output_path, output_path },
  }):sync()

  Job:new({
    command = "sed",
    args = { "-i", "_", "s#" .. M.get_working_dir(container_id) .. "#" .. M.root_path .. "#g", output_path },
  }):sync()

  if coverage_config.enabled then
    Job:new({
      command = docker_cmd,
      args = {
        "cp",
        "-a",
        container_id .. ":" .. "/tmp/coverage.xml",
        M.root_path .. "/" .. coverage_config.path,
      },
    }):sync()
  end
end

return M
