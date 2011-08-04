-- AutoIt3.lua 
-- Author: Jos van der Zande (JdeB) (compiled the scripts) 
-- August 11, 2005
-- This file contains the standard LUA scripts for AutoIt3
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Global Variables
tabs = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"
--indentchar = "\t" is autoset with use.tabs property
--+++++++++++++++++++++++++++++++++++++++++++++
--editor:AutoCSetIgnoreCase(true)
-- Callback function called each time a character is typed.
function OnChar(c)
	-- abbreviations logic will auto expand on space when SCE_AU3_EXPAND. written by Jos van der Zande (JdeB)
	local ls = editor.StyleAt[editor.CurrentPos-2]
	--if ls == 13 and c == " "  then
	if c == " "  then
		Abbreviations()
	end
	-- Valik's logic
    if (editor.Lexer == SCLEX_HTML) then    -- We only want to affect the html lexer
	--if props['FileExt'] ~= php then    -- We only want to affect the php files
--		local crt = editor:AutoCSetIgnoreCase()
--		editor:InsertText(editor.CurrentPos+1, crt)
        -- ******** Local Variables ******** --
        -- Variable mappings for SciTE menu commands
        local IDM_SHOWCALLTIP = 232
        local IDM_COMPLETE = 233
        local IDM_COMPLETEWORD = 234
        --local SCE_AU3_COMOBJ = 14 -- Not defined in current Scintilla CVS
		-- This table defines a list of styles that should not allow Auto-Complete to be invoked - changed
		--local style_table = { SCE_HPHP_COMMENT, SCE_HPHP_COMMENTLINE, SCE_HPHP_HSTRING }
		local style_table = { SCE_HPHP_DEFAULT, SCE_HPHP_SIMPLESTRING, SCE_HPHP_WORD, SCE_HPHP_VARIABLE, SCE_HPHP_HSTRING_VARIABLE, SCE_HPHP_OPERATOR, SCE_HPHP_COMPLEX_VARIABLE }
        -- **************************** --
		-- SCE_HPHP_HSTRING is "string" ie. ordinary string
        -- ******** Helper Functions ******** --
        -- Checks the style if its not in the style_table
        -- function isValidStyle(style, style_table)
            -- local i = 1
            -- while style_table[i] do
                -- if style == style_table[i] then
                    -- return false
                -- end
                -- i = i + 1
            -- end
            -- return true
        -- end    -- isValidStyle()
		
		-- changed function to return false on true and vice-versa to make sure code completion only occurs inside php blocks
		function isValidStyle(style, style_table)
            local i = 1
            while style_table[i] do
                if style == style_table[i] then
                    return true
                end
                i = i + 1
            end
            return false
        end    -- isValidStyle()
		
		-- if (c == "\t" or c == "\r") and (editor:AutoCActive()) then
			-- editor:insert(editor.SelectionEnd, "(")
			-- print("boom")
		-- end
		-- returns the character at position p as a string
		function char_at(p)
			--print(string.char(editor.CharAt[p]) .. "ddddd")
		    --return editor.CharAt[p]
			return string.char(editor.CharAt[p])
		end
				
		--print(char_at(editor.CurrentPos))
		-- For help in completing ',",[,{,(
		-- if (c == "{") then
			-- editor:insert(editor.SelectionEnd, "\r}")
		-- end
		if (c == "\r") then
			move = 0
			if (char_at(editor.CurrentPos-3) == "{" or char_at(editor.CurrentPos-3) == ":") then
				--print("alpha-beta-gamma")
				--print(char_at(editor.CurrentPos-3) .. "SD")
				move = 1
			end
			--indent
			currentindent =  editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos-1)]
			if editor.UseTabs then
				n_idents = editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos-1)] / editor.TabWidth
				s_indent = string.rep("\t",n_idents)
				indentchar = "\t"
				--print("\t" .. n_idents)
			else
				n_idents = editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos-1)]
				s_indent = string.rep(" ",n_idents)
				indentchar = " "
				--print("\tc")
			end
			if (move == 1) then
				--editor:insert(editor.SelectionEnd, s_indent)
				editor:insert(editor.CurrentPos, s_indent .. indentchar)
				editor:GotoPos(editor.CurrentPos + n_idents + 1)
				--move = 0
			elseif (move == 0) then
				editor:insert(editor.CurrentPos, s_indent)
				editor:GotoPos(editor.CurrentPos + n_idents)
			end
			--print(s_indent .. "df" .. currentindent)
				--print(editor.CurrentPos)
		end
		
		-- advanced function
--~ 		local toClose = {['(']=')',['[']=']',['"']='"',["'"]="'"}
--~ 		local toClose = {['(']=')',['[']=']'}
		local toClose = {}

		--function OnChar(charAdded)
		--	trace(charAdded)

			if toClose[c] ~= nil then
				local pos = editor.CurrentPos
				editor:ReplaceSel(toClose[c])
				editor:SetSel(pos, pos)
			end
			--return false	-- Let next handler to process event
		--	return true	-- Don't let next handler to process event
		--end

		-- 

        -- Cancels Auto-Complete if its showing
        function CancelAutoComplete()
            if editor:AutoCActive() then
                editor:AutoCCancel()
            end
            return true
        end    -- CancelAutoComplete()

        -- Invokes a SciTE menu command on the current buffer
        -- The function returns false just to make it more convenient in its usage
        function SciteMenuCommand(n)
            -- If the file hasn't been saved to disk, FilePath isn't set so check for this
            if (props["FilePath"] ~= "") then
                scite.Open(props["FilePath"] .. "\nmenucommand:" .. n)
--~             else
--~                 scite.Open("\"\"\nmenucommand:" .. n)
            end
            return false
        end    -- SciteMenuCommand()

        -- Checks a character to see if it is a valid function name character
        function isValidFuncChar(c)
            return string.find(c, "[_%w]") ~= nil
        end    -- isValidFuncChar()

        -- Checks a character to see if it is a single (') or double (") quote
        function isQuoteChar(c)
            return string.find(c, "[\"\']") ~= nil
        end    -- isQuoteChar()
        -- ****************************** --

        -- ******** Main Code ******** --
        -- Store the last set style in the variable style
        local style = editor.StyleAt[editor.CurrentPos-2]

        -- Show CallTip when a comma is typed to delimit function parameters.
        local c2 = editor:textrange(editor.CurrentPos-2, editor.CurrentPos-1)
        if (c == "," and (isValidStyle(style, style_table) or isQuoteChar(c2))) then
			--editor:insert(editor.SelectionEnd, res)
		--print()
            return SciteMenuCommand(IDM_SHOWCALLTIP)
        end
		-- insert some data! successfull
		--res = "efd"
		--editor:insert(editor.SelectionEnd, res)
        -- Show variables in Auto-Complete when.
        if (c == "$" and isValidStyle(style, style_table)) then
            return SciteMenuCommand(IDM_COMPLETEWORD)
        end

        -- Allow macro's Auto-Complete to override CallTip.
        -- if (c == "@" and isValidStyle(style, style_table)) then
            -- return SciteMenuCommand(IDM_COMPLETE)
        -- end

        -- Prevent Auto-Complete from appearing when in certain lexing styles.
        if (not isValidStyle(style, style_table)) then
            return CancelAutoComplete()
        end

        -- Prevent Auto-Complete from showing when typing _ until the second character.
        if c == "_" and editor:WordStartPosition(editor.CurrentPos) + 1 == editor.CurrentPos then
            return CancelAutoComplete()
        end

        -- Ensure the character is a valid function character.
        if not isValidFuncChar(c) then
            return false
        end
		
		

        -- If the previous character is a period, we're typing a COM method and the style
        -- of the characters isn't COM yet so its not caught above.  Cancels Auto-Complete.
		-- confirm this behavior for correction
        -- if c2 == "." then
            -- return CancelAutoComplete()
        -- end

        -- If for some reason Auto-Complete isn't showing, show it.
        if not editor:AutoCActive() then
                SciteMenuCommand(IDM_COMPLETE)
            -- fall through
        end

        -- This shows Auto-Complete for all words in the file, but only if no other Auto-Complete is showing
        if not editor:AutoCActive() then
            return SciteMenuCommand(IDM_COMPLETEWORD)
        end
		-- > 5: local length = editor:GetLength()
		-- > 6: text = editor:GetText(length)
		-- >
		-- > ...SciTEStartup.lua:5: Pane function / readable property / indexed 
		-- > writable  property
		-- > name expected
		-- >
		-- The get/set functions were turned into editor properties. 
		-- Try: editor.length or editor.Length
		--local rt = editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos)]
		--print(rt)
		
		-- testing for error styling
		-- function underline_text(pos,len,ind)
		   -- editor:StartStyling(pos,INDICS_MASK)
		   -- editor:SetStyling(len,INDIC0_MASK + ind)
		   -- editor:SetStyling(2,0)
		-- end
		-- The default indicators are
	   -- 0 green squiggly line
	   -- 1 light blue line of small T shapes
	   -- 2 light red line

		--underline_text(editor.CurrentPos-5,2,0)
		
		 
  
		-- next 3 lines work!
		--local d = editor.Indent
		--local d = editor:GetCurLine()
		--print(d)
		--editor.AutoCSetIgnoreCase = true
--		if not editor:AutoCComplete() then
--			editor:insert(editor.SelectionEnd, "\r}")
		--	AddText ( )
--		print("df")
--		end
--		AutoCSetIgnoreCase (true)
    end

    return false
end    -- OnChar()


-- editor.IndicFore[1] = tonumber("0000FF", 16)
  -- editor.IndicStyle[1] = INDIC_SQUIGGLE
  -- local function underline_text(pos,len,ind)
    -- editor:StartStyling(pos,INDICS_MASK)
    -- editor:SetStyling(len,ind)
  -- end
  -- underlines first 100 chars, red squiggle
  --underline_text(0,100,INDIC1_MASK)
  
  
  
   -- function underline_text(pos,len,ind)
   -- editor:StartStyling(pos,INDICS_MASK)
   -- editor:SetStyling(len,INDIC0_MASK + ind)
   -- editor:SetStyling(2,0)
 -- end
 -- underline_text(5,50,1)
 
   -- editor.IndicFore[1] = tonumber("0000FF", 16)
  -- editor.IndicStyle[1] = INDIC_SQUIGGLE
  -- local function underline_text(pos,len,ind)
    -- local es = editor.EndStyled
    -- editor:StartStyling(pos,ind)
    -- editor:SetStyling(len,ind)
    -- editor:StartStyling(es,31)
  -- end
  -- underline_text(0,100,INDIC1_MASK)
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- keep the number of backups as defined by backup.files = ?    by Jos van der Zande (JdeB)
-- 
function OnBeforeSave(filename)
	local sbck = tonumber(props['backup.files'])
	-- no backup specified
	if sbck == nil or sbck == 0 then
		return false
	end
	local nbck = 1
	while (sbck > nbck ) do
		local fn1 = sbck-nbck 
		local fn2 = sbck-nbck+1 
		os.remove (filename.. "." .. fn2 .. ".bak")
		if fn1 == 1 then
			os.rename (filename .. ".bak", filename .. "." .. fn2 .. ".bak")
		else
			os.rename (filename .. "." .. fn1 .. ".bak", filename .. "." .. fn2 .. ".bak")
		end
		nbck = nbck + 1
	end
	os.remove (filename.. "." .. ".bak")
	os.rename (filename, filename .. ".bak")
	return false
end

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Expand abbreviations and show tooltip when appropriated.  by Jos van der Zande (JdeB)
-- 
function Abbreviations()
	-- get current word
	from = editor:WordStartPosition(editor.CurrentPos-2)  
	to = editor:WordEndPosition(editor.CurrentPos-2)
	curword = editor:textrange(from, to)
	--print(curword)
	-- get possible replacement from abbrev.properties
	local repword = ""
	--print(props['SciteUserHome'].."\\abbrev.properties")
	local f = io.open(props['SciteDefaultHome'].."\\abbrev.properties")
	if f ~= nil then
		--print("abcd")
		local Abbrevtxt = f:read('*a')
		if Abbrevtxt then
			--print(Abbrevtxt)
			f:close()
			local rep_start = string.find(Abbrevtxt,"\n" .. string.lower(curword) .. "=")
			if rep_start ~= nil and rep_start ~= 0 then
			   rep_start = rep_start + string.len(curword) + 2
			   rep_end = string.find(Abbrevtxt .. "\n","\n",rep_start)-1
			   repword = string.sub(Abbrevtxt .. "\n",rep_start,rep_end)
			end
		end
	end
	--if repword ~= nil then
	--print(repword .. "df")
	--end
	-- if found process it
	if repword ~= nil and repword ~= "" then
		--print("gogage")
		--_ALERT("abbr:" .. curword .. "  replaced by: " .. repword .. "|" )
		-- get indent info
		local s_indent = ""
 		if editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos)] then
			currentindent =  editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos)]
			--_ALERT(currentindent)
			if editor.UseTabs then
				n_idents = editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos)] / editor.TabWidth
				s_indent = string.rep("\t",n_idents)
			else
				n_idents = editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos)]
				s_indent = string.rep(" ",n_idents)
			end
 		end
		--end
		-- remove current word
		editor:remove(from, to +1)
		-- replace text \n for LF plus the indent info 
		repword =  string.gsub(repword, "\\n", "\n" .. s_indent)
		-- replace text \t for TAB
		repword =  string.gsub(repword, "\\t", "\t")
		-- find caret position in the word
		tcaretpos = string.find(repword,"|") 
		-- when string to insert contains | then calculate the pos and remove it
		if tcaretpos ~= nil and tcaretpos ~= 0 then
			caretposword = string.find(repword,"|") -1
			caretpos = from + string.find(repword,"|") -1
			repword = string.gsub(repword, "|", "")
		else
			-- set caret pos to the end of the inserted string
			caretposword = 0
			caretpos = from + string.len(repword)
		end
		editor:insert(from,repword)
		editor:GotoPos(caretpos)
		--
		-- try to create the tooltip()
		-- get keyword/function name  part infront of the (
		braceopenpos = string.find(repword,"%(") 
		braceclosepos = string.find(repword,"%)") 
		-- when string to insert contains | then calculate the pos and remove it
		--_ALERT(braceclosepos)
		if braceclosepos ~= nil and braceclosepos < caretposword then
			-- caret pos not inside the first function 
			repword = ""
		elseif braceopenpos then
			-- get keyword/function name  part infront of the |
			repword = string.sub(repword,1,braceopenpos-1)
		elseif caretposword ~= 0 then			
			repword = string.sub(repword,1,caretposword)
		else
			repword = ""
		end
		-- Show Calltip when inside function
		if repword ~= "" and braceopenpos then
			scite.Open(props["FilePath"] .. "\nmenucommand:232")
		end
	end
end


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Insert a copy of the Bookmarked line(s) by Jos van der Zande (JdeB)
-- shortcut Ctrl+Shift+B Insert Copy of Bookmark(s)
function Copy_BookMarks() 
   editor:Home()                     -- goto beginning of the line
   ml = editor:MarkerNext(0,2)       -- Find first bookmarked line
   s_text = ""    
   while (ml > -1) do
      _ALERT("Inserted bookmarked line:" .. ml + 1 )
      s_text = s_text .. editor:GetLine(ml)      -- Add text to var
      ml = editor:MarkerNext(ml+1,2)             -- Find next bookmarked line
   end
   editor:AddText(s_text)            -- Add found text to Script
end

--++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Toggle "Use Monospaced Font" menu option by Bruce Dodson
-- this replaces the use.monospaced=1 which is removed
-- overrideshortcut Ctrl+F11 
function toggleOverrideFont()
 if props['font.override'] ~= '' then
   -- hide the file-based property
   props['font.override'] = ''
  _ALERT("==> Font set to Normal" )
 else
   -- let the property show through
   props['font.override'] = nil
   if props['font.override'] == '' then
      -- default to monospaced
      props['font.override'] = props['font.monospace']
   end
   _ALERT("==> Font set to MONOSPACE")
 end
end

--++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Used by other functions to get current word or with functions the total function
-- Writen by Valik & Jos van der Zande (JdeB)
-- 
function _GetWord(mode)
    local word = editor:GetSelText()
    if word == "" then
        if mode == nil or mode == 0 then
            -- Just get the word, no fancy processing
            from = editor:WordStartPosition(editor.CurrentPos)   
            to = editor:WordEndPosition(editor.CurrentPos)
            word = editor:textrange(from, to)
        else
            -- goto start of previous word when caret is infront of the Opening bracket or on a whitespace
            if editor.CharAt[editor.CurrentPos] == 40 or editor.CharAt[editor.CurrentPos] == 32 then
                editor:WordLeft()
            end
            -- when caret on function
            if editor.StyleAt[editor.CurrentPos] == SCE_AU3_FUNCTION or editor.StyleAt[editor.CurrentPos] == SCE_AU3_DEFAULT then
                CurrentLine = editor:LineFromPosition(editor.CurrentPos)
                SaveCurrentPos = editor.CurrentPos
                from = editor:WordStartPosition(editor.CurrentPos)  
                to = editor:WordStartPosition(editor.CurrentPos)  
                LineLastPos = editor.LineEndPosition[CurrentLine]
                local BracketsFound = 0
                -- move the caret to the end of the current word before the opening bracket
                if editor.StyleAt[editor.CurrentPos] == SCE_AU3_FUNCTION or editor.StyleAt[editor.CurrentPos] == SCE_AU3_DEFAULT then
                    editor:WordRight()
                end
                -- move passed the Bracket opening
                while (editor.CurrentPos < LineLastPos) do
                    if editor.CharAt[editor.CurrentPos] == 40 then
                        editor:CharRight()
                        BracketsFound = 1
                        break
                    end
                    editor:CharRight()
                end
                -- Loop till end of line or closing bracket of function
                if BracketsFound == 0 then
                    editor:SetSel(SaveCurrentPos, SaveCurrentPos)    -- Restore position on line
                    return _GetWord(nil)    -- Explicitly call with nil to just do simple processing
                end
                -- _ALERT("**** Function")
                while (editor.CurrentPos < LineLastPos) do
                    -- test if not inside String
                    if editor.StyleAt[editor.CurrentPos] ~= SCE_AU3_STRING then
                        -- if Opening bracket found then Add 1 to BracketsFound
                        if editor.CharAt[editor.CurrentPos] == 40 then
                            BracketsFound = BracketsFound + 1
                        end
                        -- if Closing bracket found then subtract 1 of BracketsFound
                        if editor.CharAt[editor.CurrentPos] == 41 then
                            BracketsFound = BracketsFound - 1
                        end
                    end
                    -- BracketsFound == 0 means end of selected function
                    if BracketsFound == 0 then
                        to = editor.CurrentPos + 1
                        break
                    end
                    editor:CharRight()
                end
            else
                from = editor:WordStartPosition(editor.CurrentPos)  
                to = editor:WordEndPosition(editor.CurrentPos)
            end
            word = editor:textrange(from, to)
        end
    end
    if word == "" then word = nil end
    return word
end    -- _GetWord()

--++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Jump to the selected Function
-- Writen by Valik 
-- 
function GotoDefinition()
    local word = _GetWord()
    
    if word == nil then
        print("No word selected.")
        return
    end
    local text = editor:GetText()
    place = string.find(text, "[Ff][Uu][Nn][Cc] " .. word)
    if place then 
		-- mark current line to be able to jump back
        editor:MarkerAdd(editor:LineFromPosition(editor.CurrentPos),1)
		editor:GotoLine(editor:LineFromPosition(place)) 
    else
        print("Unable to find function definition.")
    end
end    -- GotoDefinition()

--++++++++++++++++++++++++++++++++++++++++++++++++++
-- Clean up document option by Bruce Dodson
-- 
function cleanDocWhitespace()
	local trailingSpacesCount = stripTrailingSpaces(false)
	local fixedIndentationCount = fixIndentation(false)

	if (fixedIndentationCount == 0) and (trailingSpacesCount == 0) then
		print("Document was clean already; nothing to do.")
	end
end
--
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
--
function fixIndentation(reportNoMatch)
	local tabWidth = editor.TabWidth
	print("Tabsize:" .. tabWidth) 
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
--
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- list all functions available in the script  -- Jos van der Zande (JdeB)
function List_Functions()
	local sep = ':'
	local flags = SCFIND_REGEXP
	local txt = '^func'
	local s,e = editor:findtext(txt,flags,0)
	local line
	local tabl = {}
	-- find all "Func " statements and retrieve all info after it and add that to a table
	while s do 
		local l = editor:LineFromPosition(s)
		line = editor:GetLine(l)
		-- trace(line)
		line = string.sub(line,6,string.len(line)-2)
		table.insert(tabl,line)
		s,e = editor:findtext(txt,flags,e+1)
	end
	-- when table records exists then sort them and dump the table into a string and show userlist
	if table.getn(tabl) > 0 then
		table.sort(tabl,function(a,b) return string.lower(a)<string.lower(b) end)
		local sl = table.concat(tabl, sep)
		_UserListSelection = fn
		editor.AutoCSeparator = string.byte(sep)
		editor:UserListShow(12,sl)
		editor.AutoCSeparator = string.byte(' ')
	end
end
--
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Jump to selected functions   -- Jos van der Zande (JdeB)
function OnUserListSelection(t,str)
	if t == 12 then 
		local place = string.find(str, "%(" ) 
	    -- strip every thing after opening bracket when found
		if place then
			str = string.sub(str,1,place)
		end
		-- "Func " + selected function
		local s,e = editor:findtext("[Ff][Uu][Nn][Cc] " .. str,SCFIND_REGEXP,0)
		-- when found then bookmark current line and jump to Func
		if s then
			local l = editor:LineFromPosition(s)
			--?  editor:MarkerDeleteAll(1)
			editor:MarkerAdd(editor:LineFromPosition(editor.CurrentPos),1)
			editor:GotoLine(l)
		end
		return true
	else
		return false
	end
end


-- =================================================================================
-- =================================================================================
-- == Debugging and Trace functions                                               ==
-- =================================================================================
-- =================================================================================
--++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Add debug msgbox by Jos van der Zande (JdeB)
-- shortcut Ctrl+Shift+D Debug to MsgBox
function Debug_MsgBox() 
   word = editor:GetSelText()
   if string.len (word) == 0 then           -- If no text is Selected yet then select current word.
      word = _GetWord(1)
      word = string.gsub(word, "\n", "")    -- strip newline characters
      word = string.gsub(word, "\r", "")    -- strip carriage return  characters
      word = string.gsub(word, "%s", "")    -- strip space characters
   end
   if string.len (word) == 0 then 
      _ALERT("Cursor not on any text.")
      return 
   end
   word2 = string.gsub(word, "'", "''")     -- replace quote by 2 quotes
   CurrentLine = editor:LineFromPosition(editor.CurrentPos) + 1
   editor:Home()
   editor:LineDown()
   --editor:AddText("MsgBox(262144,'debug line ~" .. CurrentLine .. "' , \'" .. word2 .. "\:' & @lf & " .. word .. ") ;### Debug MSGBOX\r\n" )
   --update from mhz
	local option = tonumber(props['debug.msgbox.option'])
	if option == 2 then
		editor:AddText(tabs .. "MsgBox(262144,'Debug line ~" .. CurrentLine .. "','Selection:' & @lf & \'" .. word2 .. "\' & @lf & @lf & 'Return:' & @lf & " .. word .. " & @lf & @lf & '@Error:' & @lf & @Error & @lf & @lf & '@Extended:' & @lf & @Extended) ;### Debug MSGBOX\r\n" )
	elseif option == 1 then
		editor:AddText(tabs .. "MsgBox(262144,'Debug line ~" .. CurrentLine .. "','Selection:' & @lf & \'" .. word2 .. "\' & @lf & @lf & 'Return:' & @lf & " .. word .. " & @lf & @lf & '@Error:' & @lf & @Error) ;### Debug MSGBOX\r\n" )
	elseif option == 0 then
		editor:AddText(tabs .. "MsgBox(262144,'Debug line ~" .. CurrentLine .. "','Selection:' & @lf & \'" .. word2 .. "\' & @lf & @lf & 'Return:' & @lf & " .. word .. ") ;### Debug MSGBOX\r\n" )
	elseif option == -1 then
		editor:AddText(tabs .. "MsgBox(262144,'debug line ~" .. CurrentLine .. "' , \'" .. word2 .. "\:' & @lf & " .. word .. ") ;### Debug MSGBOX\r\n" )
	end
   --_ALERT("inserted debug msgbox.")
end   

--++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- Add debug Console message  by Jos van der Zande (JdeB)
-- shortcut Alt+D Debug to Console
-- debug.console.option=[2, 1, 0, -1]
function Debug_Console() 
   editor:BeginUndoAction()
   word = editor:GetSelText()
   if string.len (word) == 0 then           -- If no text is Selected yet then select current word.
      word = _GetWord(1)
      word = string.gsub(word, "\n", "")    -- strip newline characters
      word = string.gsub(word, "\r", "")    -- strip carriage return  characters
      word = string.gsub(word, "%s", "")    -- strip space characters
   end
   if string.len (word) == 0 then 
      _ALERT("Cursor not on any text.")
      return 
   end
   word2 = string.gsub(word, "'", "''")     -- replace quote by 2 quotes
   CurrentLine = editor:LineFromPosition(editor.CurrentPos) + 1
   editor:Home()
   editor:LineDown()
	--editor:AddText("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tConsoleWrite('@@ (" .. CurrentLine .. ") :(' & @min & ':' & @sec & ') " .. word2 .. " = ' & " .. word .. " & @lf) ;### Debug Console\r\n" )
	-- mhz proposal
	local option = tonumber(props['debug.console.option'])
	if option == 3 then
		editor:AddText(tabs .. "ConsoleWrite('@@ Debug(" .. CurrentLine .. ") : " .. word2 .. " = ' & " .. word .. " & @lf & '>Error code: ' & @error & '    Extended code: ' & @extended & '    SystemTime: ' & @hour & ':' & @min & ':' & @sec & @lf) ;### Debug Console\r\n" )
	elseif option == 2 then
		editor:AddText(tabs .. "ConsoleWrite('@@ Debug(" .. CurrentLine .. ") : " .. word2 .. " = ' & " .. word .. " & @lf & '>Error code: ' & @error & '    Extended code: ' & @extended & @lf) ;### Debug Console\r\n" )
	elseif option == 1 then
		editor:AddText(tabs .. "ConsoleWrite('@@ Debug(" .. CurrentLine .. ") : " .. word2 .. " = ' & " .. word .. " & @lf & '>Error code: ' & @error & @lf) ;### Debug Console\r\n" )
	elseif option == 0 then
		editor:AddText(tabs .. "ConsoleWrite('@@ Debug(" .. CurrentLine .. ") : " .. word2 .. " = ' & " .. word .. " & @lf) ;### Debug Console\r\n" )
	elseif option == -1 then
		editor:AddText(tabs .. "ConsoleWrite('@@ (" .. CurrentLine .. ") :(' & @min & ':' & @sec & ') " .. word2 .. " = ' & " .. word .. " & @lf) ;### Debug Console\r\n" )
	end
   editor:EndUndoAction()
   --_ALERT("inserted debug ConsoleWrite.")
end   
--++++++++++++++++++++++++++++++++++++++++++++++++++
-- Add trace lines by Jos van der Zande (JdeB)
-- debug.trace.option=[3, 2, 1, 0, -1]
function TraceAdd()
	editor:BeginUndoAction()
	local sels = editor.SelectionStart
	local sele = editor.SelectionEnd
	--   when nothing is selected then WHole script	
	if sels==sele then 
	   sels = 0
	   sele = editor.Length
	end
	local FirstLine = editor:LineFromPosition(sels)
	local LastLine = editor:LineFromPosition(sele)
	local CurrentLine = FirstLine
	editor:GotoLine(FirstLine)
	PrevLineCont = 0
	while (CurrentLine <= LastLine) do 
      local LineCode = editor:GetLine(editor:LineFromPosition(editor.CurrentPos))
	  -- fill LineCode with "" when nul to avoid function errors
	  if LineCode == nul then 
	    LineCode = ""
	  end
	  -- Skip the debug consolewrite lines
      place = string.find(LineCode, "ConsoleWrite%('@@" ) 
	  if place then
	    LineCode = ""
	  end
	  -- Skip the line contains test for @error else it could break logic
      place = string.find(LineCode, "@[Ee][Rr][Rr][Oo][Rr]" ) 
	  if place then
	    LineCode = ""
	  end
	  -- Remove CRLF
	  LineCode = string.gsub(LineCode,"\r\n","")	
      -- Only go WordRight when its not already on a Keyword and LineCode not Empty
	  if editor.StyleAt[editor.CurrentPos] ~= SCE_AU3_KEYWORD and LineCode ~= "" then
         editor:WordRight()
      end
		ls = editor.StyleAt[editor.CurrentPos]
		if LineCode ~= "" and ls ~= SCE_AU3_COMMENTBLOCK and ls ~= SCE_AU3_COMMENT and ls ~= SCE_AU3_STRING and ls ~= SCE_AU3_PREPROCESSOR and ls ~= SCE_AU3_SPECIAL then
			editor:LineEnd()
			editor:CharLeft()
			-- check for continuation lines since that would create a syntax error
			if editor.CharAt[editor.CurrentPos] == 95 and editor.StyleAt[editor.CurrentPos] ~= SCE_AU3_COMMENT then
			   CurLineCont = 1
			else
			   CurLineCont = 0
			end
			if LineCode ~= "" and PrevLineCont == 0 then
				LineCode = 	string.gsub(LineCode,"'","''")
				cl = editor:LineFromPosition(editor.CurrentPos) +2
				editor:Home()
				--- mhz's proposal
				local option = tonumber(props['debug.trace.option'])
				if option == 3 then
					editor:AddText(tabs .. "ConsoleWrite('>Error code: ' & @error & '    Extended code: ' & @extended & '    SystemTime: ' & @hour & ':' & @min & ':' & @sec & @lf & @lf & '@@ Trace(" .. cl .. ") :    " .. LineCode .. "'  & @lf) ;### Trace Console\r\n" )
				elseif option == 2 then
					editor:AddText(tabs .. "ConsoleWrite('>Error code: ' & @error & '    Extended code: ' & @extended & @lf & @lf & '@@ Trace(" .. cl .. ") :    " .. LineCode .. "'  & @lf) ;### Trace Console\r\n" )
				elseif option == 1 then
					editor:AddText(tabs .. "ConsoleWrite('>Error code: ' & @error & @lf & @lf & '@@ Trace(" .. cl .. ") :    " .. LineCode .. "'  & @lf) ;### Trace Console\r\n" )
				elseif option == 0 then
					editor:AddText(tabs .. "ConsoleWrite('@@ Trace(" .. cl .. ") :    " .. LineCode .. "'  & @lf) ;### Trace Console\r\n" )
				elseif option == -1 then
					editor:AddText(tabs .. "ConsoleWrite('@@ (" .. cl .. ") : ***Trace :" .. LineCode .. "'  & @lf) ;### Trace Console\r\n" )
				end
				editor:LineDown()
				editor:Home()
			else
				-- If continuation line then just move down
				editor:LineDown()
				editor:Home()
			end
			PrevLineCont = CurLineCont
			CurrentLine = CurrentLine + 1
		else
			-- just move down on comment and empty lines
			editor:LineDown()
			editor:Home()
			CurrentLine = CurrentLine + 1
		end
	end
   editor:EndUndoAction()
end

-- Inserts a ConsoleWrite() for each function by Valik
-- Debug: Add Trace Functions
function FunctionTraceAdd()
    -- Pattern to match
    -- If the comment "FunctionTraceSkip" is found after the closing ), then
    -- that function will not get a trace statement added.
    local sPattern = "()([Ff][Uu][Nn][Cc][%s]*([%w_]*)%(.-%))([^\r\n]*)"

    -- Local callback function which processes any captures and returns the replacement text
    local i = 0    -- Used as a counter in pat_match to offset the line numbers
    local function pat_match(m1, m2, m3, m4)
        if string.find(m4, ";[%s]*[Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn][Tt][Rr][Aa][Cc][Ee][Ss][Kk][Ii][Pp]") then
            return m2 .. m4
        end
        i = i + 1
        return m2 .. m4 .. "\r\n\tConsoleWrite('@@ (" .. editor:LineFromPosition(m1)+i .. ") :(' & @MIN & ':' & @SEC & ') " .. m3 .. "()' & @CR) ;### Trace Function "
    end

    TraceRemoveAll()    -- Remove any previous traces so we don't get duplicates
    _ReplaceDocByPattern(sPattern, pat_match)    -- Perform replacement
end    -- FunctionTraceAdd()

-- Remove all Function Trace statements  by Valik
-- tool $(au3) 2 Ctrl+Alt+Shift+T Debug: Remove Trace Functions
function TraceRemoveAll()
    -- Pattern to match
    local sPattern = "\r\n[%s]*(ConsoleWrite%([^\r\n]-%) ;### Trace[^\r\n]+)"
    
    -- Local callback function which processes any captures and returns the replacement text
    local function pat_match()
        return ""
    end
    FunctionTraceUncomment()    -- Remove any commented functions first
    _ReplaceDocByPattern(sPattern, pat_match)    -- Perform replacement
end    -- FunctionTraceRemove()

-- Comment all Function Trace statements  by Valik
-- Debug: Comment Trace Functions
function FunctionTraceComment()
    -- Pattern to match
    local sPattern = "\r\n[%s]*(ConsoleWrite%([^\r\n]-%) ;### Trace[^\r\n]+)"
    
    -- Local callback function which processes any captures and returns the replacement text
    local function pat_match(m1)
        return "\r\n;\t" .. m1
    end

    _ReplaceDocByPattern(sPattern, pat_match)    -- Perform replacement
end    -- FunctionTraceComment()

-- Uncomment all Function Trace statements  by Valik
-- Debug: Uncomment Trace Functions
function FunctionTraceUncomment()
    -- Pattern to match
    local sPattern = "\r\n[%s]*;[%s]*(ConsoleWrite%([^\r\n]-%) ;### Trace[^\r\n]+)"
    
    -- Local callback function which processes any captures and returns the replacement text
    local function pat_match(m1)
        return "\r\n\t" .. m1
    end

    _ReplaceDocByPattern(sPattern, pat_match)    -- Perform replacement
end    -- FunctionTraceUncomment()

-- Comment all Debug lines  by Valik/Jdeb
-- Ctrl+Shift+D Debug: Comment all lines
function CommentAllDebug() 
    -- Pattern to match
    local sPattern1 = "\r\n[%s]*(ConsoleWrite%([^\r\n]-%) ;### Debug[^\r\n]+)"
    local sPattern2 = "\r\n[%s]*(MsgBox%([^\r\n]-%) ;### Debug[^\r\n]+)"
    local sPattern3 = "\r\n[%s]*(ConsoleWrite%([^\r\n]-%) ;### Trace[^\r\n]+)"

	-- Local callback function which processes any captures and returns the replacement text
    local function pat_match(m1)
        return "\r\n;" .. tabs .. m1
    end

    _ReplaceDocByPattern(sPattern1, pat_match, false, false)    -- Perform replacement
    _ReplaceDocByPattern(sPattern2, pat_match, false, false)    -- Perform replacement
    _ReplaceDocByPattern(sPattern3, pat_match, false, false)    -- Perform replacement
end
-- Uncomment all Debug lines by Valik/Jdeb
-- Ctrl+Alt+D Debug: Uncomment all lines
function unCommentAllDebug()
    -- Pattern to match
    local sPattern1 = "\r\n[%s]*;[%s]*(ConsoleWrite%([^\r\n]-%) ;### Debug[^\r\n]+)"
    local sPattern2 = "\r\n[%s]*;[%s]*(MsgBox%([^\r\n]-%) ;### Debug[^\r\n]+)"
    local sPattern3 = "\r\n[%s]*;[%s]*(ConsoleWrite%([^\r\n]-%) ;### Trace[^\r\n]+)"
    
    -- Local callback function which processes any captures and returns the replacement text
    local function pat_match(m1)
        return "\r\n" .. tabs .. m1
    end

    _ReplaceDocByPattern(sPattern1, pat_match, false, false)    -- Perform replacement
    _ReplaceDocByPattern(sPattern2, pat_match, false, false)    -- Perform replacement
    _ReplaceDocByPattern(sPattern3, pat_match, false, false)    -- Perform replacement
end
-- Remove all Debug MsgBox/Console lines  by Valik/Jdeb
-- Debug: Remove all lines
function Remove_Debug()
    -- Pattern to match
    local sPattern1 = "\r\n[%s]*(ConsoleWrite%([^\r\n]-%) ;### Debug[^\r\n]+)"
    local sPattern2 = "\r\n[%s]*(MsgBox%([^\r\n]-%) ;### Debug[^\r\n]+)"
    
    -- Local callback function which processes any captures and returns the replacement text
    local function pat_match()
        return ""
    end
    unCommentAllDebug()    -- Remove any commented functions first
    _ReplaceDocByPattern(sPattern1, pat_match)    -- Perform replacement
    _ReplaceDocByPattern(sPattern2, pat_match)    -- Perform replacement
end
--  by Valik
-- Replaces all occurences of a specific pattern by calling a user-defined callback function
-- sPat - The regular expresion pattern to match.
-- fnPatMatch - A callback function which will be called for each match.  The captures from
--    the pattern will be passed as arguments to the function.  Return the replacement string.
-- bPosCanChange - Set this to true if lines will be added/removed.  This will enable the exact
--    position to be restored after the modifications are complete.
-- bRemove - Set this to true if lines will be removed.  This ensures the editor is set in the
--    proper location after modification.
function _ReplaceDocByPattern(sPat, fnPatMatch)
    local pos = editor.CurrentPos    -- Current position before modification
    local caret_line = editor:LineFromPosition(pos)    -- Line number to return to.
    local first_line = editor.FirstVisibleLine    -- The first visible line in the buffer
    local line_offset = 0    -- Number of lines inserted above the caret's original position
    local column = pos - editor:PositionFromLine(caret_line)    -- Convert back to beginning of line
    local old_line_count = editor.LineCount
    
    sPat = "()" .. sPat    -- Internal capture to record the position of each match.
    -- Local function which builds a string from the pattern matches.
    local function pat_match(m1, m2, m3, m4, m5, m6, m7, m8, m9)
        if pos > m1 then line_offset = line_offset + 1 end
        return fnPatMatch(m2, m3, m4, m5, m6, m7, m8, m9)
    end

    editor:BeginUndoAction()
    
    local sDoc = editor:GetText()
    local sNewDoc = string.gsub(sDoc, sPat, pat_match)
    editor:SetText(sNewDoc)

    local new_line_count = editor.LineCount
    
    if old_line_count > new_line_count then
        line_offset = line_offset * -1
    elseif old_line_count == new_line_count then
        line_offset = 0
    end
    
    pos = editor:PositionFromLine(caret_line + line_offset)
    editor:GotoPos(pos + column)
    editor:LineScroll(0, first_line - editor.FirstVisibleLine + line_offset)

    editor:EndUndoAction()
end    -- _ReplaceDocByPattern()

-- Open the #Include file from your script.     JdeB
-- Alt+I Open Include Files
function OpenInclude()
    -- currentline text
	local CurrentLine = editor:GetLine(editor:LineFromPosition(editor.CurrentPos))
	-- Exclude #include-once
	if string.find(CurrentLine, "%#[Ii][Nn][Cc][Ll][Uu][Dd][Ee][-][Oo][Nn][Cc][Ee]" ) then
		return true
	end
	-- find #include
	local place = string.find(CurrentLine, "%#[Ii][Nn][Cc][Ll][Uu][Dd][Ee]" ) 
	-- strip every thing after opening bracket when found
	if place then
		IncFile = string.sub(CurrentLine,place + 8)
		IncFile = string.gsub(IncFile,"\r","")  -- strip CR characters
		IncFile = string.gsub(IncFile,"\n","")	-- strip LF characters	
		IncFile = string.gsub(IncFile,"%s","")	-- strip whitespace characters	
	else
	    print("Not on #include line.")
		return true
	end
	-- check if its a generic included file
	local place = string.find(IncFile, "<" ) 
	-- 
	if place then
		IncFile = string.gsub(IncFile,"\<","")		
		IncFile = string.gsub(IncFile,"\>","")		
		IncFile1 = props['autoit3dir'] .. "\\include\\" .. IncFile
		IncFile2 = IncFile
	else  -- Else it is a include file in the script dir 
		IncFile1 = string.gsub(IncFile,"\"","")		
		IncFile2 = props['autoit3dir'] .. "\\include\\" .. IncFile1
	end
	-- Check if  first choice  file exists
	-- Else Check if  Second choice  file exists
	if io.open (IncFile1 , "r") then 
		io.close ()
		scite.Open(IncFile1)
	elseif io.open (IncFile2 , "r") then 
		io.close ()
		scite.Open(IncFile2)
	else
	    print("File not found at :" .. IncFile1 .. " or " .. IncFile2)
	end
end    --
