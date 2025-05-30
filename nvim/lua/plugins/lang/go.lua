-- ~/.config/nvim/lua/mohamad/go.lua
if true then
  return {}
end
local M = {}

function M.golangci_config()
  return "--config=.golangci.yml"
end

function M.golangci_filename()
  return ""
end

function M.golangcilint_args()
  local ok, output = pcall(vim.fn.system, { "golangci-lint", "version" })
  if not ok then return {} end

  if string.find(output, "version v1") or string.find(output, "version 1") then
    return {
      "run",
      "--out-format=json",
      "--issues-exit-code=0",
      "--show-stats=false",
      "--print-issued-lines=false",
      "--print-linter-name=false",
      M.golangci_config(),
      M.golangci_filename(),
    }
  end

  return {
    "run",
    "--output.json.path=stdout",
    "--output.text.path=",
    "--output.tab.path=",
    "--output.html.path=",
    "--output.checkstyle.path=",
    "--output.code-climate.path=",
    "--output.junit-xml.path=",
    "--output.teamcity.path=",
    "--output.sarif.path=",
    "--issues-exit-code=0",
    "--show-stats=false",
    M.golangci_config(),
    M.golangci_filename(),
  }
end

return M
