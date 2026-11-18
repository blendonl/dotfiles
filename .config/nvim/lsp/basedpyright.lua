local function project_venv_python(root_dir)
  if not root_dir then
    return nil
  end
  local python = vim.fs.joinpath(root_dir, ".venv", "bin", "python")
  if vim.uv.fs_stat(python) then
    return python
  end
end

return {
  before_init = function(_, config)
    local python = project_venv_python(config.root_dir)
    if python then
      config.settings.python = vim.tbl_extend("force", config.settings.python or {}, { pythonPath = python })
    end
  end,
  settings = {
    basedpyright = {
      disableOrganizeImports = true,
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  },
}
