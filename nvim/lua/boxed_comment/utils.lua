-- utils.lua
local M = {}

-- Get comment prefix from the current buffer
function M.get_comment_prefix()
  local cs = vim.bo.commentstring or ""
  local prefix = cs:match("^(.-)%%s") or "//"
  return prefix:gsub("%s+$", "")
end

-- Wrap a single line by max width
local function wrap_line(line, max_width)
  local words, current, wrapped = {}, "", {}
  for word in line:gmatch("%S+") do
    if #current + #word + 1 > max_width then
      table.insert(wrapped, current)
      current = word
    else
      current = current ~= "" and current .. " " .. word or word
    end
  end
  if current ~= "" then
    table.insert(wrapped, current)
  end
  return wrapped
end

-- Wrap multiple lines
function M.wrap_lines(lines, max_width)
  local result = {}
  for _, line in ipairs(lines) do
    vim.list_extend(result, wrap_line(line, max_width))
  end
  return result
end

-- Center lines inside a fixed width
function M.center_lines(lines, width)
  local centered = {}
  for _, line in ipairs(lines) do
    local pad = math.floor((width - #line) / 2)
    local padded = string.rep(" ", pad) .. line
    table.insert(centered, padded .. string.rep(" ", width - #padded))
  end
  return centered
end

-- Optionally strip existing comment prefix from lines
function M.strip_comment_prefix(lines, prefix)
  local stripped = {}
  for _, line in ipairs(lines) do
    local clean = line:gsub("^%s*" .. vim.pesc(prefix), "")
    table.insert(stripped, vim.trim(clean))
  end
  return stripped
end

return M
