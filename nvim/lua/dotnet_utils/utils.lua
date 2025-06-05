local M = {}

function M.is_valid_csproj(path)
  return path and path:match("%.csproj$")
end

function M.is_job_alive(job_id)
  if not job_id then
    return false
  end
  return vim.fn.jobwait({ job_id }, 0)[1] == -1
end

return M
