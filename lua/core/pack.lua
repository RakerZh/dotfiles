local uv, api, fn = vim.loop, vim.api, vim.fn
local helper = require('core.helper')
local pack = {}
pack.__index = pack

function pack:load_modules_packages()
  ---@diagnostic disable-next-line: param-type-mismatch
  local modules_dir = vim.fs.joinpath(self.config_path, 'lua', 'modules')
  self.repos = {}

  local list = vim.fs.find('package.lua', { path = modules_dir, type = 'file', limit = 10 })
  if #list == 0 then
    return
  end

  local disable_modules = {}

  if fn.exists('g:disable_modules') == 1 then
    disable_modules = vim.split(vim.g.disable_modules, ',', { trimempty = true })
  end

  vim.iter(list):map(function(f)
    local _, pos = f:find(modules_dir)
    f = f:sub(pos - 6, #f - 4)
    if not vim.tbl_contains(disable_modules, f) then
      require(f)
    end
  end)
end

function pack:boot_strap()
  self.helper = require('core.helper')
  self.data_path = self.helper.data_path()
  self.config_path = self.helper.config_path()
  ---@diagnostic disable-next-line: param-type-mismatch
  local lazy_path = vim.fs.joinpath(self.data_path, 'lazy', 'lazy.nvim')
  local state = uv.fs_stat(lazy_path)
  if not state then
    local cmd = '!git clone https://github.com/folke/lazy.nvim ' .. lazy_path
    api.nvim_command(cmd)
  end
  vim.opt.runtimepath:prepend(lazy_path)
  local lazy = require('lazy')
  local opts = {
    ---@diagnostic disable-next-line: param-type-mismatch
    lockfile = vim.fs.joinpath(self.data_path, 'lazy-lock.json'),
    dev = { path = '~/workspace' },
  }
  self:load_modules_packages()
  lazy.setup(self.repos, opts)
end

_G.packadd = function(repo)
  if not pack.repos then
    pack.repos = {}
  end

  pack.repos[#pack.repos + 1] = repo
end

return pack
