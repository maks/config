
function stripTrailingSpaces(reportNoMatch)
	local count = 0
	local fs,fe = editor:findtext("[ \\t]+$", SCFIND_REGEXP)
	if fe then
		repeat
			count = count + 1
			editor:remove(fs,fe)
			fs,fe = editor:findtext("[ \\t]+$", SCFIND_REGEXP, fs)
		until not fe
		print("Removed trailing spaces from " .. count .. " line(s).")
	elseif reportNoMatch then
		print("Document was clean already; nothing to do.")
	end
	return count
end

function fixIndentation(reportNoMatch)
	local tabWidth = editor.TabWidth
	local count = 0
	if editor.UseTabs then
		-- for each piece of indentation that includes at least one space
		for m in editor:match("^[\\t ]* [\\t ]*", SCFIND_REGEXP) do
			-- figure out the indentation size
			local indentSize = editor.LineIndentation[editor:LineFromPosition(m.pos)]
			local spaceCount = math.mod(indentSize, tabWidth)
			local tabCount = (indentSize - spaceCount) / tabWidth
			local fixedIndentation = string.rep('\t', tabCount) .. string.rep(' ', spaceCount)

			if fixedIndentation ~= m.text then
				m:replace(fixedIndentation)
				count = count + 1
			end
		end
	else
		-- for each piece of indentation that includes at least one tab
		for m in editor:match("^[\\t ]*\t[\\t ]*", SCFIND_REGEXP) do
			-- just change all of the indentation to spaces
			m:replace(string.rep(' ', editor.LineIndentation[editor:LineFromPosition(m.pos)]))
			count = count + 1
		end
	end
	if count > 0 then
		print("Fixed indentation for " .. count .. " line(s).")
	elseif reportNoMatch then
		print("Document was clean already; nothing to do.")
	end
	return count
end

function cleanDocWhitespace()
	local trailingSpacesCount = stripTrailingSpaces(false)
	local fixedIndentationCount = fixIndentation(false)

	if (fixedIndentationCount == 0) and (trailingSpacesCount == 0) then
		print("Document was clean already; nothing to do.")
	end
end

--switch_buffers.lua - http://lua-users.org/wiki/SciteBufferSwitch
--drops down a list of buffers, in recently-used order

local buffers = {}
local append = table.insert

local function buffer_switch(f)
--- swop the new current buffer with the last one!
  local idx  
  for i,file in ipairs(buffers) do
     if file == f then  idx = i; break end
  end
  if idx then 
     table.remove(buffers,idx)
     table.insert(buffers,1,f)
  else append(buffers,f)
  end
end

function OnOpen(f)
  buffer_switch(f)
end

function OnSwitchFile(f)
  buffer_switch(f)
end

function do_buffer_list()
  local s = ''
  local sep = ';'
  local n = table.getn(buffers)
  for i = 2,n-1 do
      s = s..buffers[i]..sep
  end
  s = s..buffers[n]
  _UserListSelection = fn
  editor.AutoCSeparator = string.byte(sep)
  editor:UserListShow(12,s)
  editor.AutoCSeparator = string.byte(' ')
end

function OnUserListSelection(t,str)
  if t == 12 then 
     scite.Open(str)
     return true
  else
     return false
  end
end
