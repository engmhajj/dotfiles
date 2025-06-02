local TreeHandler = {}

function TreeHandler:new()
  local o = {
    root = {},
    stack = {},
    current = nil,
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

function TreeHandler:reset()
  self.root = {}
  self.stack = {}
  self.current = nil
end

function TreeHandler:starttag(tag, attributes)
  local t = {
    _attr = attributes,
  }

  if not self.current then
    self.root[tag] = t
    self.current = t
  else
    if not self.current[tag] then
      self.current[tag] = {}
    end

    table.insert(self.stack, self.current)

    if type(self.current[tag]) == "table" and self.current[tag]._attr then
      self.current[tag] = { self.current[tag] }
    end

    if type(self.current[tag]) == "table" then
      table.insert(self.current[tag], t)
    else
      self.current[tag] = t
    end

    self.current = t
  end
end

function TreeHandler:endtag(tag)
  self.current = table.remove(self.stack)
end

function TreeHandler:text(text)
  if text:match("^%s*$") then
    return
  end

  if self.current then
    self.current._text = (self.current._text or "") .. text
  end
end

return TreeHandler
