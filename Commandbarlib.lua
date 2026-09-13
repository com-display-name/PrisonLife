local CommandBar = {
    ScreenGui = nil,
    MainFrame = nil,
    NotificationHolder = nil,
	AutoComplete = nil,
	Tooltip = nil,
	_acConn = nil,
	_acGen = nil,
    Commands = {},
    BuiltInCommands = {},
    Aliases = {},
    CmdHistory = {},
    HistoryIdx = 1,
    Variables = {},
    PreDefinedVariables = {},
    LastCommandArgs = {},
    MaxHistory = 200,
    MaxVariables = 100,
    Prefix = ".",
	UnloadCallbacks = {},
    SelectorKeywords = {
        ["all"] = true,
        ["others"] = true,
        ["me"] = true,
        ["allies"] = true,
        ["team"] = true,
        ["enemies"] = true,
        ["nonteam"] = true,
        ["friends"] = true,
        ["nonfriends"] = true,
        ["alive"] = true,
        ["dead"] = true,
    },
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")


function CommandBar:New(ClassName, Properties, Children)
	local Inst = Instance.new(ClassName)

	for Property, Value in pairs(Properties or {}) do
		Inst[Property] = Value
	end

	if (Inst:IsA("Frame") or Inst:IsA("TextLabel") or Inst:IsA("TextButton") or Inst:IsA("ImageLabel") or Inst:IsA("ImageButton") or Inst:IsA("ScrollingFrame")) and (Properties == nil or Properties.BorderSizePixel == nil) then
		Inst.BorderSizePixel = 0
	end

	for _, Child in ipairs(Children or {}) do
		if not Child then break end
		Child.Parent = Inst
	end

	return Inst
end
function CommandBar:MakeDraggable(DragFrame, MoveFrame)
	local Dragging = false
	local DragStart
	local StartPosition

	DragFrame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPosition = MoveFrame.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end

		if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local Delta = Input.Position - DragStart

		local X = StartPosition.X.Offset + Delta.X
		local Y = StartPosition.Y.Offset + Delta.Y

		MoveFrame.Position = UDim2.new(
			StartPosition.X.Scale,
			X,
			StartPosition.Y.Scale,
			Y
		)
	end)
    return DragFrame
end
function CommandBar:GetTextBounds(Text, TextSize, Font,  MaxWidth) : Vector2
	local TextBounds = Instance.new("GetTextBoundsParams")
	TextBounds.Text = Text
	TextBounds.Size = TextSize
	TextBounds.Width = MaxWidth or math.huge
	TextBounds.Font = Font
	local a = TextService:GetTextBoundsAsync(TextBounds)
	TextBounds:Destroy()
	return a
end
function CommandBar:MakeBlur()
	return CommandBar:New("UIShadow", {
        BlurRadius = UDim.new(0, 20),
        Color = Color3.fromRGB(20,20,20),
        Spread = UDim2.new(0, 10, 0, 10),
        Transparency = 0.4,

    })
end

local function trim(s)
	return (s:match("^%s*(.-)%s*$"))
end

local function countMap(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

local function clearTable(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local function isInstance(v)
	if typeof ~= nil then
		local ok, res = pcall(typeof, v)
		if ok then
			return res == "Instance"
		end
	end
	return false
end

local function parseSelectorTokens(s)
	local tokens = {}
	local currentSign = "+"
	local current = ""
	local function flush()
		local t = trim(current)
		if t ~= "" then
			table.insert(tokens, { Sign = currentSign, Token = t })
		end
		current = ""
	end
	for i = 1, #s do
		local c = s:sub(i, i)
		if c == "+" or c == "-" then
			flush()
			currentSign = c
		elseif c == "," then
			flush()
		else
			current = current .. c
		end
	end
	flush()
	return tokens
end

local function capitalizeSelectorToken(tok)
	if tok == "" then return tok end
	return tok:sub(1, 1):upper() .. tok:sub(2):lower()
end

local function getOrderedArguments(args)
	if not args then return {} end
	local ordered = {}
	for key, config in pairs(args) do
		table.insert(ordered, { Key = key, Config = config })
	end

	local function slotIndex(item)
		if type(item.Config) == "table" and tonumber(item.Config.Index) ~= nil then
			return tonumber(item.Config.Index)
		end
		return tonumber(item.Key) or 999
	end
	table.sort(ordered, function(a, b)
		local aIdx = slotIndex(a)
		local bIdx = slotIndex(b)
		if aIdx ~= bIdx then
			return aIdx < bIdx
		end
		return tostring(a.Key) < tostring(b.Key)
	end)
	return ordered
end

local function evalMath(expr)
	local tokens = {}
	local i = 1
	local n = #expr
	while i <= n do
		local c = expr:sub(i, i)
		if c:match("%s") then
			i = i + 1
		elseif c:match("%d") or (c == "." and expr:sub(i + 1, i + 1):match("%d")) then
			local j = i
			while j <= n and expr:sub(j, j):match("[%d%.]") do
				j = j + 1
			end
			local num = tonumber(expr:sub(i, j - 1))
			if num == nil then
				return nil, "bad number near '" .. expr:sub(i, j - 1) .. "'"
			end
			table.insert(tokens, { Kind = "num", Value = num })
			i = j
		elseif c == "(" or c == ")" then
			table.insert(tokens, { Kind = c })
			i = i + 1
		elseif c:match("[%+%-%*/%%^]") then
			table.insert(tokens, { Kind = "op", Value = c })
			i = i + 1
		else
			return nil, "unexpected character '" .. c .. "'"
		end
	end
	if #tokens == 0 then
		return nil, "empty expression"
	end

	local pos = 1
	local function peek()
		return tokens[pos]
	end
	local parseExpr, parseTerm, parseUnary, parsePower, parsePrimary
	function parsePrimary()
		local tk = peek()
		if tk == nil then
			return nil, "unexpected end of expression"
		end
		if tk.Kind == "num" then
			pos = pos + 1
			return tk.Value
		end
		if tk.Kind == "(" then
			pos = pos + 1
			local v, err = parseExpr()
			if v == nil then
				return nil, err
			end
			local closing = peek()
			if closing == nil or closing.Kind ~= ")" then
				return nil, "missing closing parenthesis"
			end
			pos = pos + 1
			return v
		end
		return nil, "unexpected '" .. tostring(tk.Value or tk.Kind) .. "'"
	end
	function parsePower()
		local base, err = parsePrimary()
		if base == nil then
			return nil, err
		end
		local tk = peek()
		if tk and tk.Kind == "op" and tk.Value == "^" then
			pos = pos + 1
			local exp, err2 = parseUnary()
			if exp == nil then
				return nil, err2
			end
			base = base ^ exp
		end
		return base
	end
	function parseUnary()
		local tk = peek()
		if tk and tk.Kind == "op" and (tk.Value == "-" or tk.Value == "+") then
			pos = pos + 1
			local v, err = parsePower()
			if v == nil then
				return nil, err
			end
			if tk.Value == "-" then
				return -v
			end
			return v
		end
		return parsePower()
	end
	function parseTerm()
		local v, err = parseUnary()
		if v == nil then
			return nil, err
		end
		while true do
			local tk = peek()
			if tk and tk.Kind == "op" and (tk.Value == "*" or tk.Value == "/" or tk.Value == "%") then
				pos = pos + 1
				local r, err2 = parseUnary()
				if r == nil then
					return nil, err2
				end
				if tk.Value == "*" then
					v = v * r
				elseif tk.Value == "/" then
					if r == 0 then
						return nil, "division by zero"
					end
					v = v / r
				else
					if r == 0 then
						return nil, "modulo by zero"
					end
					v = v % r
				end
			else
				break
			end
		end
		return v
	end
	function parseExpr()
		local v, err = parseTerm()
		if v == nil then
			return nil, err
		end
		while true do
			local tk = peek()
			if tk and tk.Kind == "op" and (tk.Value == "+" or tk.Value == "-") then
				pos = pos + 1
				local r, err2 = parseTerm()
				if r == nil then
					return nil, err2
				end
				if tk.Value == "+" then
					v = v + r
				else
					v = v - r
				end
			else
				break
			end
		end
		return v
	end

	local result, err = parseExpr()
	if result == nil then
		return nil, err
	end
	if peek() ~= nil then
		return nil, "unexpected '" .. tostring(peek().Value or peek().Kind) .. "'"
	end
	if result ~= result or result == math.huge or result == -math.huge then
		return nil, "result is not a finite number"
	end
	return result
end

local function isMathLike(s)
	if not s:find("%d") then
		return false
	end
	if not s:find("[%+%-%*/%%^]") then
		return false
	end
	return s:match("^[%d%s%+%-%*/%%^%(%)%.]+$") ~= nil
end

function CommandBar:WriteLine(text, color)
	if CommandBar.Notify then
		CommandBar:Notify("", text, 5)
	end
end

function CommandBar:ClearOutput()
end

function CommandBar:AddTooltip(BoundingFrame, Text)
	if not Text then return end

	local IsInFrame = false
	local IsShown = false
	local Tooltip = CommandBar.Tooltip

	BoundingFrame.MouseEnter:Connect(function()
		if not Tooltip then return end
		Tooltip.Text = Text
		

		local Size = CommandBar:GetTextBounds(Text, 12, CommandBar.Tooltip.FontFace) + Vector2.new(6, 6)

		IsInFrame = true

		task.delay(0.5, function()
			if not IsInFrame then return end
			IsShown = true
			Tooltip.Visible = true
			TweenService:Create(Tooltip, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(0, Size.X, 0, Size.Y)}):Play()

			task.delay(0.075, function() Tooltip.TextTransparency = 0 end)
			local Mouse = UserInputService:GetMouseLocation()
			Tooltip.Position = UDim2.fromOffset(Mouse.X + 16, Mouse.Y + 16)
		end)
	end)
	BoundingFrame.MouseLeave:Connect(function()
		if not Tooltip then return end
		IsInFrame = false

		if IsShown then
			IsShown = false
			TweenService:Create(Tooltip, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			Tooltip.Text = ""
			task.delay(0.075, function() Tooltip.TextTransparency = 1 end)
			task.delay(0.15, function() Tooltip.Visible = false end)
		end
	end)
	BoundingFrame.MouseMoved:Connect(function()
		if not IsShown then return end
		local Mouse = UserInputService:GetMouseLocation()
		Tooltip.Position = UDim2.fromOffset(Mouse.X + 16, Mouse.Y + 16)
	end)
end

function CommandBar:__FindCommand(name)
	local lower = name:lower()
	return self.Aliases[lower] or self.BuiltInCommands[lower] or self.Commands[lower]
end

function CommandBar:__GetOrderedArguments(cmdData)
	return getOrderedArguments(cmdData.Arguments)
end

function CommandBar:ClearHistory()
	clearTable(self.CmdHistory)
	self.HistoryIdx = 1
end

function CommandBar:__PushHistory(entry)
	if self.CmdHistory[#self.CmdHistory] == entry then
		self.HistoryIdx = #self.CmdHistory + 1
		return
	end
	table.insert(self.CmdHistory, entry)
	if #self.CmdHistory > self.MaxHistory then
		table.remove(self.CmdHistory, 1)
	end
	self.HistoryIdx = #self.CmdHistory + 1
end

function CommandBar:__GetHistory(direction)
	if #self.CmdHistory == 0 then return nil end
	if direction == "Up" then
		self.HistoryIdx = math.max(1, self.HistoryIdx - 1)
	elseif direction == "Down" then
		self.HistoryIdx = math.min(#self.CmdHistory + 1, self.HistoryIdx + 1)
	end
	return self.CmdHistory[self.HistoryIdx] or ""
end

function CommandBar:__IsSelectorKeyword(str)
	return self.SelectorKeywords[str:lower()] == true
end

function CommandBar:__IsSelectorExpression(str)
	local lower = str:lower()
	if str:sub(1, 1) == "@" then return true end
	if self.SelectorKeywords[lower] then return true end
	if str:find(",", 1, true) then return true end
	if str:find("[+%-]") then
		for token in str:gmatch("[^+%-]+") do
			local t = trim(token):lower()
			if self.SelectorKeywords[t] then return true end
		end
	end
	return false
end

function CommandBar:__FormatSelector(selector)
	local tokens = parseSelectorTokens(selector)
	if #tokens == 0 then return "" end
	local function norm(t)
		return t:lower()
	end
	local base = capitalizeSelectorToken(norm(tokens[1].Token))
	if tokens[1].Sign == "-" then
		base = "- " .. base
	end
	if #tokens == 1 then return base end
	local out = base
	local i = 2
	while i <= #tokens do
		local sign = tokens[i].Sign
		local group = {}
		while i <= #tokens and tokens[i].Sign == sign do
			table.insert(group, norm(tokens[i].Token))
			i = i + 1
		end
		local sep = " + "
		if sign == "-" then
			sep = " - "
		end
		if #group > 1 then
			out = out .. sep .. "(" .. table.concat(group, ", ") .. ")"
		else
			out = out .. sep .. group[1]
		end
	end
	return out
end

local function matchUserToken(token)
	if token == "" then return nil end
	if token:sub(1, 1) == "@" then
		token = token:sub(2)
		if token == "" then return nil end
	end
	local lower = token:lower()
	local players = Players:GetPlayers()
	for _, p in ipairs(players) do
		if p.Name:lower() == lower or p.DisplayName:lower() == lower then
			return p
		end
	end
	for _, p in ipairs(players) do
		if p.Name:lower():find(lower, 1, true) or p.DisplayName:lower():find(lower, 1, true) then
			return p
		end
	end
	return nil
end

function CommandBar:__GetPlayer(search)
	return matchUserToken(search)
end

function CommandBar:__IsPlayerName(str)
	if self:__IsSelectorExpression(str) then return false end
	return self:__GetPlayer(str) ~= nil
end

function CommandBar:__IsCommandName(str)
	return self:__FindCommand(str) ~= nil
end

function CommandBar:GetCompletions(prefix)
	local lower = prefix:lower()
	local seen = {}
	local out = {}
	local function check(tbl)
		for name in pairs(tbl) do
			if name:sub(1, #lower) == lower and not seen[name] then
				seen[name] = true
				table.insert(out, name)
			end
		end
	end
	check(self.Commands)
	check(self.BuiltInCommands)
	check(self.Aliases)
	table.sort(out)
	return out
end

function CommandBar:GetPlayerCompletions(prefix)
	prefix = tostring(prefix or "")
	local hasAt = prefix:sub(1, 1) == "@"
	local clean = prefix
	if hasAt then
		clean = prefix:sub(2)
	end
	if clean:sub(1, 1) == '"' or clean:sub(1, 1) == "'" then
		clean = clean:sub(2)
	end
	local lower = clean:lower()
	local out = {}
	local seen = {}
	local function push(v)
		if v ~= "" and not seen[v] then
			seen[v] = true
			table.insert(out, v)
		end
	end
	if not hasAt then
		for kw in pairs(self.SelectorKeywords) do
			if kw:sub(1, #lower) == lower then
				push(kw)
			end
		end
	end
	local ok, players = pcall(function() return Players:GetPlayers() end)
	if ok and type(players) == "table" then
		for _, p in ipairs(players) do
			local nameOk, name = pcall(function() return p.Name end)
			local dispOk, disp = pcall(function() return p.DisplayName end)
			if nameOk and type(name) == "string" and name ~= "" then
				local matches = name:lower():sub(1, #lower) == lower
				if not matches and dispOk and type(disp) == "string" and disp ~= "" then
					matches = disp:lower():sub(1, #lower) == lower
				end
				if matches then
					if hasAt then
						push("@" .. name)
					else
						push(name)
					end
				end
			end
		end
	end
	table.sort(out)
	return out
end

function CommandBar:GetVariableCompletions(prefix)
	prefix = tostring(prefix or "")
	if prefix:sub(1, 1) ~= "$" then
		return {}
	end
	local lower = prefix:lower()
	local out = {}
	local function check(tbl)
		for name in pairs(tbl) do
			local full = "$" .. name
			if full:lower():sub(1, #lower) == lower then
				table.insert(out, full)
			end
		end
	end
	check(self.Variables)
	check(self.PreDefinedVariables)
	table.sort(out)
	return out
end

function CommandBar:__GetArgConfig(cmdData, argIndex)
	if not cmdData or not cmdData.Arguments then return nil end
	local ordered = self:__GetOrderedArguments(cmdData)
	return ordered[argIndex] and ordered[argIndex].Config or nil
end

function CommandBar:GetArgumentCompletions(cmdName, argIndex, prefix)
	local res = self:__GetArgumentCompletionsInner(cmdName, argIndex, prefix)
	if cmdName then
		local cmdData = self:__FindCommand(tostring(cmdName))
		if cmdData and cmdData.Arguments then
			local lower = tostring(prefix or ""):lower()
			local seen = {}
			for _, v in ipairs(res) do
				seen[v] = true
			end
			for _, item in ipairs(self:__GetOrderedArguments(cmdData)) do
				if type(item.Config) == "table" and item.Config.Type == "flag" then
					local nm = tostring(item.Config.Name or item.Key)
					local cands = { "--" .. nm, nm }
					for _, cand in ipairs(cands) do
						if cand:lower():sub(1, #lower) == lower and not seen[cand] then
							seen[cand] = true
							table.insert(res, cand)
						end
					end
				end
			end
			table.sort(res)
		end
	end
	return res
end

function CommandBar:__GetArgumentCompletionsInner(cmdName, argIndex, prefix)
	prefix = tostring(prefix or "")
	if prefix:sub(1, 1) == "$" then
		return self:GetVariableCompletions(prefix)
	end
	local cmdData = nil
	if cmdName then
		cmdData = self:__FindCommand(tostring(cmdName))
	end
	local cfg = nil
	if cmdData then
		cfg = self:__GetArgConfig(cmdData, argIndex)
	end
	local lower = prefix:lower()
	if cmdData and cfg and (cfg.Name == "CommandName" or cfg.Name == "Command" or cfg.Name == "Action") then
		local cmds = self:GetCompletions(prefix)
		if cmdName and tostring(cmdName):lower() == "history" then
			local verbs = { "show", "clear" }
			local out = {}
			for _, v in ipairs(verbs) do
				if v:sub(1, #lower) == lower then
					table.insert(out, v)
				end
			end
			for _, c in ipairs(cmds) do
				table.insert(out, c)
			end
			return out
		end
		if cfg.Type == "string" and #cmds > 0 then
			if not (tostring(cmdName):lower() == "alias" and argIndex == 2) then
				return cmds
			end
		end
	end
	if cfg then
		local t = cfg.Type
		if t == "boolean" then
			local opts = { "true", "false", "on", "off", "yes", "no", "1", "0" }
			local out = {}
			for _, o in ipairs(opts) do
				if o:sub(1, #lower) == lower then
					table.insert(out, o)
				end
			end
			return out
		elseif t == "player" or t == "players" then
			return self:GetPlayerCompletions(prefix)
		elseif t == "integer" or t == "number" then
			return self:GetVariableCompletions(prefix)
		else
			local seen = {}
			local out = {}
			local function pushList(list)
				for _, v in ipairs(list) do
					if not seen[v] then
						seen[v] = true
						table.insert(out, v)
					end
				end
			end
			pushList(self:GetPlayerCompletions(prefix))
			pushList(self:GetCompletions(prefix))
			pushList(self:GetVariableCompletions(prefix))
			table.sort(out)
			return out
		end
	end
	local seen = {}
	local out = {}
	local function pushList(list)
		for _, v in ipairs(list) do
			if not seen[v] then
				seen[v] = true
				table.insert(out, v)
			end
		end
	end
	pushList(self:GetPlayerCompletions(prefix))
	pushList(self:GetCompletions(prefix))
	if prefix:sub(1, 1) == "$" then
		pushList(self:GetVariableCompletions(prefix))
	end
	table.sort(out)
	return out
end

function CommandBar:GetTokenInfo(fullText, cursorPos)
	fullText = tostring(fullText or "")
	cursorPos = tonumber(cursorPos) or (#fullText + 1)
	if cursorPos < 1 then cursorPos = 1 end
	if cursorPos > #fullText + 1 then cursorPos = #fullText + 1 end
	local before = fullText:sub(1, cursorPos - 1)
	local segStart = 1
	do
		local lastSemi, lastAnd, lastOr = 0, 0, 0
		for i = 1, #before do
			local c = before:sub(i, i)
			if c == ";" then
				lastSemi = i
			elseif c == "&" and before:sub(i + 1, i + 1) == "&" then
				lastAnd = i + 1
			elseif c == "|" and before:sub(i + 1, i + 1) == "|" then
				lastOr = i + 1
			end
		end
		local m = math.max(lastSemi, lastAnd, lastOr)
		if m > 0 then
			segStart = m + 1
		end
	end
	local segmentBefore = before:sub(segStart)
	local token = segmentBefore:match("%S+$") or ""
	local tokenStart = #before - #token + 1
	if token == "" then
		tokenStart = cursorPos
	end
	local beforeToken = before:sub(1, tokenStart - 1)
	local segBeforeToken = beforeToken:sub(segStart)
	local isFirst = trim(segBeforeToken) == ""
	local cmdName = nil
	local argIndex = 1
	if not isFirst then
		local segText = trim(before:sub(segStart))
		local first = segText:match("^(%S+)")
		if first then
			if first:sub(1, 1) == "!" then
				first = first:sub(2)
			end
			cmdName = first
		end
		local parsedBefore = self:__ParseArgs(segBeforeToken)
		if #parsedBefore == 0 then
			argIndex = 1
		else
			local flagNames = {}
			local cdata = cmdName and self:__FindCommand(tostring(cmdName)) or nil
			if cdata and cdata.Arguments then
				for _, it in ipairs(self:__GetOrderedArguments(cdata)) do
					if type(it.Config) == "table" and it.Config.Type == "flag" then
						flagNames[tostring(it.Config.Name or it.Key):lower()] = true
						flagNames[tostring(it.Key):lower()] = true
					end
				end
			end
			local slots = 0
			for pIdx = 2, #parsedBefore do
				local tok = parsedBefore[pIdx]
				local v = tostring(tok.Value or ""):lower():gsub("^%-+", "")
				if not tok.Quoted and flagNames[v] then
				else
					slots = slots + 1
				end
			end
			argIndex = slots + 1
			if argIndex < 1 then argIndex = 1 end
		end
	end
	return token, tokenStart, isFirst, cmdName, argIndex
end

function CommandBar:GetArgInfoRows(cmdName, argIndex)
	local rows = {}
	if not cmdName then
		return rows
	end
	local cmdData = self:__FindCommand(tostring(cmdName))
	if not cmdData or not cmdData.Arguments then
		return rows
	end
	local ordered = self:__GetOrderedArguments(cmdData)
	local start = tonumber(argIndex) or 1
	if start < 1 then
		start = 1
	end
	for oi = start, #ordered do
		local item = ordered[oi]
		local cfg = item.Config
		if type(cfg) == "table" then
			local label = tostring(cfg.Name or item.Key)
			local t = tostring(cfg.Type or "string")
			if t == "flag" then
				table.insert(rows, "[--" .. label .. ": flag]")
			elseif cfg.Required and cfg.Default == nil then
				table.insert(rows, "<" .. label .. ": " .. t .. ">")
			else
				table.insert(rows, "[" .. label .. ": " .. t .. "]")
			end
		end
	end
	return rows
end

function CommandBar:GetSuggestions(fullText, cursorPos)
	fullText = tostring(fullText or "")
	local token, tokenStart, isFirst, cmdName, argIndex = self:GetTokenInfo(fullText, cursorPos)
	local items = {}
	local applicable = false
	local clean = token
	if clean:sub(1, 1) == '"' or clean:sub(1, 1) == "'" then
		clean = clean:sub(2)
	end
	if token:sub(1, 1) == "!" then
		local sub = token:sub(2)
		local cmds = self:GetCompletions(sub)
		for _, c in ipairs(cmds) do
			table.insert(items, "!" .. c)
		end
		applicable = true
	elseif isFirst then
		items = self:GetCompletions(token)
		applicable = true
	else
		local cmdData = cmdName and self:__FindCommand(tostring(cmdName)) or nil
		local cfg = cmdData and self:__GetArgConfig(cmdData, argIndex) or nil
		local isCmdNameArg = type(cfg) == "table"
			and (cfg.Name == "CommandName" or cfg.Name == "Command" or cfg.Name == "Action")
			and cfg.Type == "string"
			and not (tostring(cmdName):lower() == "alias" and argIndex == 2)
		if isCmdNameArg then
			if tostring(cmdName):lower() == "history" then
				local lower = clean:lower()
				for _, v in ipairs({ "show", "clear" }) do
					if v:sub(1, #lower) == lower then
						table.insert(items, v)
					end
				end
				for _, c in ipairs(self:GetCompletions(clean)) do
					table.insert(items, c)
				end
			else
				items = self:GetCompletions(clean)
			end
			applicable = true
		else
			items = self:GetArgInfoRows(cmdName, argIndex)
			applicable = false
		end
	end
	return {
		Items = items,
		Token = token,
		TokenStart = tokenStart,
		IsFirst = isFirst,
		CmdName = cmdName,
		ArgIndex = argIndex,
		Applicable = applicable,
	}
end

function CommandBar:ApplyCompletion(fullText, cursorPos, tokenStart, completion)
	fullText = tostring(fullText or "")
	cursorPos = tonumber(cursorPos) or (#fullText + 1)
	completion = tostring(completion or "")
	local before = fullText:sub(1, tokenStart - 1)
	local after = fullText:sub(cursorPos)
	local token = fullText:sub(tokenStart, cursorPos - 1)
	local lead = token:sub(1, 1)
	if (lead == '"' or lead == "'") and completion:sub(1, 1) ~= lead then
		completion = lead .. completion
	end
	local suffix = ""
	if after == "" then
		local _, _, isFirst = self:GetTokenInfo(fullText, cursorPos)
		if isFirst and completion:sub(-1) ~= " " then
			suffix = " "
		end
	end
	local newText = before .. completion .. suffix .. after
	local newCursor = #before + #completion + #suffix + 1
	return newText, newCursor
end

function CommandBar:__ResolvePlayerSelector(selector)
	local LocalPlayer = Players.LocalPlayer
	local result = {}
	local included = {}
	local excluded = {}
	local order = {}
	local seenOrder = {}

	local function addPlayer(p)
		if p and not included[p.Name] then
			included[p.Name] = p
			if not seenOrder[p.Name] then
				seenOrder[p.Name] = true
				table.insert(order, p.Name)
			end
		end
		if p then
			excluded[p.Name] = nil
		end
	end

	local function removePlayer(p)
		if p then
			excluded[p.Name] = p
			included[p.Name] = nil
		end
	end

	local function isOnSameTeam(p)
		if not LocalPlayer or not LocalPlayer.Team or not p.Team then return false end
		return LocalPlayer.Team == p.Team
	end

	local friendCache = {}
	local function isFriend(p)
		if not LocalPlayer then return false end
		if friendCache[p.UserId] ~= nil then return friendCache[p.UserId] end
		local ok, res = pcall(function()
			return LocalPlayer:IsFriendsWith(p.UserId)
		end)
		local val = false
		if ok and res == true then
			val = true
		end
		friendCache[p.UserId] = val
		return val
	end

	local function resolveSelectorToken(sel, exclude)
		local lower = trim(sel):lower()
		if lower == "" then return end
		if lower == "all" then
			for _, p in ipairs(Players:GetPlayers()) do
				if exclude then removePlayer(p) else addPlayer(p) end
			end
		elseif lower == "others" then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		elseif lower == "me" then
			if LocalPlayer then
				if exclude then removePlayer(LocalPlayer) else addPlayer(LocalPlayer) end
			end
		elseif lower == "allies" or lower == "team" then
			for _, p in ipairs(Players:GetPlayers()) do
				if isOnSameTeam(p) then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		elseif lower == "enemies" or lower == "nonteam" then
			for _, p in ipairs(Players:GetPlayers()) do
				if not isOnSameTeam(p) then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		elseif lower == "friends" then
			for _, p in ipairs(Players:GetPlayers()) do
				if isFriend(p) then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		elseif lower == "nonfriends" then
			for _, p in ipairs(Players:GetPlayers()) do
				if not isFriend(p) then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		elseif lower == "alive" then
			for _, p in ipairs(Players:GetPlayers()) do
				local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		elseif lower == "dead" then
			for _, p in ipairs(Players:GetPlayers()) do
				local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then
					if exclude then removePlayer(p) else addPlayer(p) end
				end
			end
		else
			local mention = lower:match("^@(.+)$")
			local target = nil
			if mention then
				target = matchUserToken(trim(mention))
			else
				target = matchUserToken(lower)
			end
			if target then
				if exclude then removePlayer(target) else addPlayer(target) end
			else
				self:WriteLine(string.format("Player '%s' not found in selector.", trim(sel)), Color3.fromRGB(255, 100, 100))
			end
		end
	end

	local tokens = parseSelectorTokens(selector)
	if #tokens == 0 then
		resolveSelectorToken(trim(selector), false)
	else
		for _, entry in ipairs(tokens) do
			local tok = trim(entry.Token)
			if tok ~= "" then
				resolveSelectorToken(tok, entry.Sign == "-")
			end
		end
	end

	for _, name in ipairs(order) do
		local p = included[name]
		if p then
			table.insert(result, p)
		end
	end

	return result
end

function CommandBar:__ResolveValue(str)
	if self:__IsSelectorExpression(str) then
		local players = self:__ResolvePlayerSelector(str)
		if #players == 1 then
			return players[1]
		elseif #players > 1 then
			return players
		end
		return nil
	else
		local p = self:__GetPlayer(str)
		if p then return p end
		return str
	end
end

function CommandBar:__ParseArgs(rawString)
	local args = {}
	local i = 1
	local len = #rawString

	local function expandVariables(val)
		local wasVariable = false
		local out = val:gsub("%$(%w+)", function(varName)
			local found = self.Variables[varName]
			if found == nil then
				found = self.PreDefinedVariables[varName]
			end
			if found ~= nil then
				wasVariable = true
				return tostring(found)
			end
			return "$" .. varName
		end)
		return out, wasVariable
	end

	local function readUntilQuote(quoteChar, startPos)
		local j = startPos
		while j <= len do
			local c = rawString:sub(j, j)
			if c == "\\" then
				j = j + 2
			elseif c == quoteChar then
				return j
			else
				j = j + 1
			end
		end
		return nil
	end

	local function processEscapes(val)
		return (val:gsub("\\.", function(match)
			local c = match:sub(2, 2)
			if c == "n" then return "\n"
			elseif c == "t" then return "\t"
			elseif c == "\\" then return "\\"
			elseif c == '"' then return '"'
			elseif c == "'" then return "'"
			elseif c == "$" then return "$"
			else return c end
		end))
	end

	while i <= len do
		local char = rawString:sub(i, i)
		if char:match("%s") then
			i = i + 1
		elseif char == '"' or char == "'" then
			local quote = char
			local start = i + 1
			local endPos = readUntilQuote(quote, start)
			if endPos then
				local val = rawString:sub(start, endPos - 1)
				val = processEscapes(val)
				local wasVariable
				val, wasVariable = expandVariables(val)
				table.insert(args, { Value = val, Quoted = true, WasVariable = wasVariable, QuoteChar = quote })
				i = endPos + 1
			else
				local val = rawString:sub(i + 1)
				val = processEscapes(val)
				local wasVariable
				val, wasVariable = expandVariables(val)
				table.insert(args, { Value = val, Quoted = true, WasVariable = wasVariable, QuoteChar = quote })
				break
			end
		elseif char == "\\" then
			if i + 1 <= len then
				local escaped = rawString:sub(i + 1, i + 1)
				local val = processEscapes("\\" .. escaped)
				local wasVariable
				val, wasVariable = expandVariables(val)
				table.insert(args, { Value = val, Quoted = false, WasVariable = wasVariable })
				i = i + 2
			else
				table.insert(args, { Value = "", Quoted = false, WasVariable = false })
				i = i + 1
			end
		else
			local start = i
			local j = i
			while j <= len do
				local c = rawString:sub(j, j)
				if c:match("%s") then
					break
				elseif c == "\\" then
					j = j + 2
				else
					j = j + 1
				end
			end
			local val = rawString:sub(start, math.min(j, len + 1) - 1)
			i = j
			val = processEscapes(val)
			local wasVariable
			val, wasVariable = expandVariables(val)
			table.insert(args, { Value = val, Quoted = false, WasVariable = wasVariable })
		end
	end
	return args
end

function CommandBar:__SegmentInput(trimmed)
	local segments = {}
	local current = ""
	local inQuote = false
	local quoteChar = ""
	local i = 1
	local len = #trimmed

	while i <= len do
		local char = trimmed:sub(i, i)
		local nextTwo = trimmed:sub(i, i + 1)
		if char == '"' or char == "'" then
			if not inQuote then
				inQuote = true
				quoteChar = char
			elseif char == quoteChar then
				local bsCount = 0
				local k = i - 1
				while k >= 1 and trimmed:sub(k, k) == "\\" do
					bsCount = bsCount + 1
					k = k - 1
				end
				if bsCount % 2 == 0 then
					inQuote = false
				end
			end
			current = current .. char
		elseif inQuote then
			current = current .. char
		elseif char == "\\" then
			if i + 1 <= len then
				current = current .. trimmed:sub(i, i + 1)
				i = i + 1
			end
		elseif char == ";" then
			local text = trim(current)
			if text ~= "" then
				table.insert(segments, { Text = text, NextOperator = ";" })
			end
			current = ""
		elseif nextTwo == "&&" then
			local text = trim(current)
			if text ~= "" then
				table.insert(segments, { Text = text, NextOperator = "&&" })
			end
			current = ""
			i = i + 1
		elseif nextTwo == "||" then
			local text = trim(current)
			if text ~= "" then
				table.insert(segments, { Text = text, NextOperator = "||" })
			end
			current = ""
			i = i + 1
		else
			current = current .. char
		end
		i = i + 1
	end

	local lastText = trim(current)
	if lastText ~= "" then
		table.insert(segments, { Text = lastText, NextOperator = nil })
	end

	return segments
end

function CommandBar:__ExecuteLegacy(command, arguments)
	local key = tostring(command or ""):lower()
	local cmdData = self:__FindCommand(key)
	if not cmdData then
		warn("[CommandBar] Unknown command: \"" .. tostring(command) .. "\"")
		return false, "unknown command"
	end
	local mapArgs = {}
	for i, v in ipairs(arguments) do
		mapArgs[tostring(i)] = v
	end
	local success, result = pcall(cmdData.Function, mapArgs)
	if not success then
		warn("[CommandBar] Error in command \"" .. tostring(cmdData.Description or key) .. "\": " .. tostring(result))
		return false, result
	end
	return true, result
end

function CommandBar:Execute(raw, arguments, NoErrors)
	if type(self) == "string" then
		arguments = raw
		raw = self
		self = CommandBar
	end
	if type(arguments) == "table" then
		return self:__ExecuteLegacy(raw, arguments)
	end

	local trimmed = trim(tostring(raw or ""))
	if trimmed == "" then
		return false, "empty input"
	end
	self:__PushHistory(trimmed)
	local segments = self:__SegmentInput(trimmed)
	local lastSuccess = true
	local lastResult = nil
	local nextOp = nil
	for _, segment in ipairs(segments) do
		if nextOp == "&&" and not lastSuccess then
			nextOp = segment.NextOperator
		elseif nextOp == "||" and lastSuccess then
			nextOp = segment.NextOperator
		elseif segment.Text == "" then
			nextOp = segment.NextOperator
		else
			lastSuccess, lastResult = self:__ExecuteSegment(segment.Text)
			nextOp = segment.NextOperator
		end
	end
	return lastSuccess, lastResult
end

function CommandBar:ExecuteString(raw, IsMessage)
	if type(self) == "string" then
		raw = self
		self = CommandBar
	end
	return self:Execute(raw, IsMessage)
end

function CommandBar:__ExecuteSegment(text)
	if text:sub(1, 1) == "!" then
		local cmdName = trim(text:sub(2)):lower()
		local lastArgs = self.LastCommandArgs[cmdName]
		if lastArgs then
			local cmdData = self:__FindCommand(cmdName)
			if cmdData then
				local success, err = pcall(cmdData.Function, lastArgs)
				if not success then
					self:WriteLine("Error executing command: " .. tostring(err), Color3.fromRGB(255, 100, 100))
					return false, err
				end
				return true
			else
				self:WriteLine("Command not found: " .. cmdName, Color3.fromRGB(255, 100, 100))
				return false, "unknown command"
			end
		else
			self:WriteLine(string.format("No previous arguments found for command '%s'.", cmdName), Color3.fromRGB(255, 100, 100))
			return false, "no previous args"
		end
	end

	local varName, varValue = text:match("^%$(%w+)%s*=%s*(.+)$")
	if varName then
		if countMap(self.Variables) >= self.MaxVariables and self.Variables[varName] == nil then
			self:WriteLine(string.format("Variable limit reached (%d).", self.MaxVariables), Color3.fromRGB(255, 100, 100))
			return false, "variable limit"
		end
		local quote, content = varValue:match("^([\"'])(.-)%1$")
		local stripped = content or varValue
		stripped = (stripped:gsub("%$(%w+)", function(v)
			local found = self.Variables[v]
			if found == nil then
				found = self.PreDefinedVariables[v]
			end
			if found == nil then
				found = "$" .. v
			end
			return tostring(found)
		end))
		if not quote then
			stripped = trim(stripped)
			local player = self:__GetPlayer(stripped)
			if player then
				stripped = player.Name
			end
		end
		self.Variables[varName] = stripped
		self:WriteLine(string.format("Variable set: %s = '%s'", varName, tostring(stripped)), Color3.fromRGB(100, 255, 100))
		return true, stripped
	end

	if text == "$$" then
		self:WriteLine("Variables:", Color3.fromRGB(255, 230, 100))
		local count = 0
		for name, value in pairs(self.Variables) do
			self:WriteLine(string.format("  $%s = %s", name, tostring(value)), Color3.fromRGB(200, 200, 200))
			count = count + 1
		end
		for name, value in pairs(self.PreDefinedVariables) do
			self:WriteLine(string.format("  $%s = %s (read-only)", name, tostring(value)), Color3.fromRGB(150, 150, 150))
			count = count + 1
		end
		if count == 0 then
			self:WriteLine("  (No variables defined)", Color3.fromRGB(150, 150, 150))
		end
		return true
	end

	local readName = text:match("^%$(%w+)$")
	if readName then
		local value = self.Variables[readName]
		if value == nil then
			value = self.PreDefinedVariables[readName]
		end
		if value == nil then
			value = "nil"
		end
		self:WriteLine(tostring(value), Color3.fromRGB(200, 200, 200))
		return true, value
	end

	return self:__InternalExecute(text)
end

function CommandBar:__BuildUsage(cmdName, cmdData)
	local parts = { tostring(cmdName) }
	if cmdData and cmdData.Arguments then
		for _, item in ipairs(self:__GetOrderedArguments(cmdData)) do
			local cfg = item.Config
			if type(cfg) == "table" then
				local label = tostring(cfg.Name or item.Key)
				if cfg.Type == "flag" then
					label = "[--" .. label .. "]"
				elseif cfg.Required and cfg.Default == nil then
					label = "<" .. label .. ">"
				else
					label = "[" .. label .. "]"
				end
				table.insert(parts, label)
			end
		end
	end
	return "Usage: " .. table.concat(parts, " ")
end

function CommandBar:__InternalExecute(trimmed)
	local parsed = self:__ParseArgs(trimmed)
	if #parsed == 0 then return true end
	local name = parsed[1].Value:lower()
	local rawArgs = {}
	for idx = 2, #parsed do
		table.insert(rawArgs, parsed[idx])
	end

	self:WriteLine("> " .. trimmed, Color3.fromRGB(140, 140, 140))

	local cmdData = self:__FindCommand(name)
	if not cmdData then
		local lowerName = name
		local matches = {}
		local seenCmd = {}
		local function collect(tbl)
			for cmdName, cfg in pairs(tbl) do
				if not seenCmd[cfg] and cmdName:sub(1, #lowerName) == lowerName then
					seenCmd[cfg] = true
					table.insert(matches, cmdName)
				end
			end
		end
		collect(self.Commands)
		collect(self.BuiltInCommands)
		if #matches == 1 then
			cmdData = self:__FindCommand(matches[1])
			name = matches[1]
		elseif #matches > 1 then
			table.sort(matches)
			self:WriteLine(string.format("'%s' is ambiguous. Did you mean: %s", name, table.concat(matches, ", ")), Color3.fromRGB(255, 200, 100))
			return false, "ambiguous"
		else
			if isMathLike(trimmed) then
				local mathVal = evalMath(trimmed)
				if mathVal ~= nil then
					self:WriteLine("= " .. tostring(mathVal), Color3.fromRGB(100, 255, 100))
					return true, mathVal
				end
			end
			self:WriteLine("'" .. name .. "' is not recognized as a command. Type 'help' for a list.", Color3.fromRGB(220, 80, 80))
			return false, "unknown command"
		end
	end

	local mapArgs = {}
	if cmdData.Arguments then
		local ordered = self:__GetOrderedArguments(cmdData)
		local flagDefs = {}
		for _, item in ipairs(ordered) do
			if type(item.Config) == "table" and item.Config.Type == "flag" then
				flagDefs[tostring(item.Config.Name or item.Key):lower()] = item.Key
				flagDefs[tostring(item.Key):lower()] = item.Key
			end
		end
		local positional = {}
		for _, argData in ipairs(rawArgs) do
			local tokenStr = tostring(argData.Value or "")
			local stripped = tokenStr:lower():gsub("^%-+", "")
			if not argData.Quoted and flagDefs[stripped] and mapArgs[flagDefs[stripped]] == nil then
				mapArgs[flagDefs[stripped]] = true
			else
				table.insert(positional, argData)
			end
		end
		for _, item in ipairs(ordered) do
			if type(item.Config) == "table" and item.Config.Type == "flag" and mapArgs[item.Key] == nil then
				local dflt = item.Config.Default
				if dflt == nil then
					dflt = false
				end
				mapArgs[item.Key] = dflt
			end
		end
		local lastPos = 0
		for op, it in ipairs(ordered) do
			if not (type(it.Config) == "table" and it.Config.Type == "flag") then
				lastPos = op
			end
		end
		local positionalIdx = 1
		local consumedAll = false
		for orderPos, item in ipairs(ordered) do
			local key = item.Key
			local config = item.Config
			if type(config) == "table" and config.Type == "flag" then
			else
				local argData = positional[positionalIdx]
				local rawVal = nil
				if argData then
					rawVal = argData.Value
				end
				if rawVal == nil then
					if config.Required and config.Default == nil then
						self:WriteLine(string.format("Missing required argument: %s", config.Name or key), Color3.fromRGB(255, 100, 100))
						self:WriteLine(self:__BuildUsage(name, cmdData), Color3.fromRGB(150, 200, 255))
						self:WriteLine(string.format("Type 'man %s' to see the manual for this command.", name), Color3.fromRGB(200, 200, 200))
						return false, "missing argument"
					end
					mapArgs[key] = config.Default
				else
					local rawStr = rawVal
					if config.Type == "player" or config.Type == "players" then
						local targetStr = rawStr
						local literalOnly = argData and argData.Quoted or false
						if not literalOnly and orderPos == lastPos then
							consumedAll = true
							if positionalIdx < #positional then
								local parts = {}
								for r = positionalIdx, #positional do
									table.insert(parts, positional[r].Value)
								end
								targetStr = table.concat(parts, " ")
							end
						end
						local list = nil
						if literalOnly then
							local single = matchUserToken(targetStr)
							if single then
								list = { single }
							else
								list = {}
							end
						else
							list = self:__ResolvePlayerSelector(targetStr)
						end
						if #list == 0 then
							self:WriteLine(string.format("Player '%s' not found.", targetStr), Color3.fromRGB(255, 100, 100))
							self:WriteLine(self:__BuildUsage(name, cmdData), Color3.fromRGB(150, 200, 255))
							return false, "player not found"
						end
						if config.Type == "players" then
							mapArgs[key] = list
						else
							mapArgs[key] = list[1]
						end
						if #list > 1 then
							mapArgs["_players"] = list
						end
					elseif config.Type == "string" then
						if argData and argData.Quoted then
							mapArgs[key] = tostring(rawStr)
						elseif self:__IsSelectorExpression(rawStr) then
							local resolved = self:__ResolveValue(rawStr)
							if type(resolved) == "table" then
								local names = {}
								for _, p in ipairs(resolved) do
									table.insert(names, p.Name)
								end
								mapArgs[key] = table.concat(names, ",")
							elseif isInstance(resolved) then
								mapArgs[key] = resolved.Name
							else
								mapArgs[key] = tostring(rawStr)
							end
						elseif self:__IsPlayerName(rawStr) then
							local p = self:__GetPlayer(rawStr)
							if p then
								mapArgs[key] = p.Name
							else
								mapArgs[key] = tostring(rawStr)
							end
						else
							mapArgs[key] = tostring(rawStr)
						end
					elseif config.Type == "any" then
						local mathVal = nil
						if isMathLike(rawStr) then
							mathVal = evalMath(rawStr)
						end
						if mathVal ~= nil then
							mapArgs[key] = mathVal
						elseif self:__IsSelectorExpression(rawStr) then
							local resolved = self:__ResolveValue(rawStr)
							if resolved ~= nil then
								mapArgs[key] = resolved
							else
								mapArgs[key] = rawStr
							end
						elseif self:__IsPlayerName(rawStr) then
							local p = self:__GetPlayer(rawStr)
							if p then
								mapArgs[key] = p
							else
								mapArgs[key] = rawStr
							end
						else
							mapArgs[key] = rawStr
						end
					elseif config.Type == "integer" or config.Type == "number" then
						local num = tonumber(rawStr)
						if num == nil and isMathLike(rawStr) then
							num = evalMath(rawStr)
						end
						if num == nil then
							self:WriteLine(string.format("Argument '%s' expected a number but got '%s'.", config.Name or key, rawStr), Color3.fromRGB(255, 100, 100))
							self:WriteLine(self:__BuildUsage(name, cmdData), Color3.fromRGB(150, 200, 255))
							return false, "bad number"
						end
						if config.Type == "integer" and math.floor(num) ~= num then
							self:WriteLine(string.format("Argument '%s' expected an integer but got '%s'.", config.Name or key, rawStr), Color3.fromRGB(255, 100, 100))
							self:WriteLine(self:__BuildUsage(name, cmdData), Color3.fromRGB(150, 200, 255))
							return false, "bad integer"
						end
						if config.Type == "integer" then
							mapArgs[key] = math.floor(num)
						else
							mapArgs[key] = num
						end
					elseif config.Type == "boolean" then
						local lower = tostring(rawStr):lower()
						local boolMap = { ["true"] = true, ["1"] = true, ["yes"] = true, ["on"] = true, ["false"] = false, ["0"] = false, ["no"] = false, ["off"] = false }
						if boolMap[lower] == nil then
							self:WriteLine(string.format("Argument '%s' expected true/false but got '%s'.", config.Name or key, rawStr), Color3.fromRGB(255, 100, 100))
							self:WriteLine(self:__BuildUsage(name, cmdData), Color3.fromRGB(150, 200, 255))
							return false, "bad boolean"
						end
						mapArgs[key] = boolMap[lower]
					else
						mapArgs[key] = rawStr
					end
				end
				positionalIdx = positionalIdx + 1
			end
		end
		if not consumedAll and #ordered > 0 and positionalIdx <= #positional then
			local extras = {}
			for e = positionalIdx, #positional do
				table.insert(extras, tostring(positional[e].Value))
			end
			self:WriteLine(string.format("Too many arguments: '%s'.", table.concat(extras, " ")), Color3.fromRGB(255, 100, 100))
			self:WriteLine(self:__BuildUsage(name, cmdData), Color3.fromRGB(150, 200, 255))
			return false, "too many arguments"
		end
	end
	for i, v in ipairs(rawArgs) do
		if mapArgs[tostring(i)] == nil then
			mapArgs[tostring(i)] = v.Value
		end
	end
	self.LastCommandArgs[name] = mapArgs
	local success, err = pcall(cmdData.Function, mapArgs)
	if not success then
		self:WriteLine("Error executing command: " .. tostring(err), Color3.fromRGB(255, 100, 100))
		return false, err
	end
	return true, err
end

function CommandBar:Register(name, descriptionOrCallback, callback)
	local description
	local fn
	if type(descriptionOrCallback) == "function" then
		description = ""
		fn = descriptionOrCallback
	else
		description = descriptionOrCallback or ""
		fn = callback
	end

	assert(type(name) == "string" and #name > 0, "Register: Name must be a non-empty string")
	assert(type(fn) == "function", "Register: missing callback for command \"" .. tostring(name) .. "\"")
	assert(type(description) == "string", "Register: Description must be a string")

	local legacyFn = fn
	self:RegisterCommand(name, {
		Description = description,
		Arguments = {},
		Function = function(mapArgs)
			local arr = {}
			local i = 1
			while mapArgs[tostring(i)] ~= nil do
				arr[i] = mapArgs[tostring(i)]
				i = i + 1
			end
			return legacyFn(arr, table.concat(arr, " "))
		end,
	})
end

function CommandBar:Unregister(name)
	return self:UnregisterCommand(name)
end


function CommandBar:RegisterCommand(name, config)
	if not name or type(config) ~= "table" or type(config.Function) ~= "function" then
		warn("Invalid command configuration injected.")
		return
	end
	if config.Description and type(config.Description) ~= "string" then
		warn("Command description must be a string.")
		return
	end
	if config.Arguments ~= nil and type(config.Arguments) ~= "table" then
		error("RegisterCommand: Arguments must be a table.")
	end
	local commandData = {
		Description = config.Description or "No description provided.",
		Arguments = config.Arguments or {},
		Function = config.Function,
	}
	local label = type(name) == "string" and name or "command"
	local orderedCheck = getOrderedArguments(commandData.Arguments)
	local seenOptional = false
	local seenOptionalLabel = ""
	for _, item in ipairs(orderedCheck) do
		local cfg = item.Config
		if type(cfg) ~= "table" then
			error(string.format("RegisterCommand: argument '%s' of '%s' must be a table.", tostring(item.Key), label))
		end
		if cfg.Type ~= nil and cfg.Type ~= "player" and cfg.Type ~= "players" and cfg.Type ~= "string" and cfg.Type ~= "any" and cfg.Type ~= "integer" and cfg.Type ~= "number" and cfg.Type ~= "boolean" and cfg.Type ~= "flag" then
			warn(string.format("RegisterCommand: argument '%s' of '%s' has unknown Type '%s'; it will be treated as raw text.", tostring(item.Key), label, tostring(cfg.Type)))
		end
		if cfg.Type ~= "flag" then
			local optional = (not cfg.Required) or (cfg.Default ~= nil)
			if optional then
				seenOptional = true
				seenOptionalLabel = tostring(cfg.Name or item.Key)
			elseif seenOptional then
				error(string.format("RegisterCommand: required argument '%s' of '%s' follows optional argument '%s'; put required arguments first.", tostring(cfg.Name or item.Key), label, seenOptionalLabel))
			end
		end
	end
	local function registerName(n)
		local lower = trim(n):lower()
		if lower == "" then
			warn("Command name cannot be empty.")
			return
		end
		if self.SelectorKeywords[lower] then
			warn(string.format("Command name '%s' conflicts with selector keyword.", n))
			return
		end
		if self.Commands[lower] or self.BuiltInCommands[lower] then
			warn(string.format("Command '%s' already registered - overwriting.", n))
		end
		self.Commands[lower] = commandData
	end
	if type(name) == "table" then
		for _, alias in ipairs(name) do
			if type(alias) == "string" then
				registerName(alias)
			else
				warn("Invalid command name type inside table: expected string, got " .. type(alias))
			end
		end
	elseif type(name) == "string" then
		registerName(name)
	else
		warn("Invalid command name type: expected string or table, got " .. type(name))
	end
	if config.Aliases and type(config.Aliases) == "table" then
		for _, alias in ipairs(config.Aliases) do
			if type(alias) == "string" then
				registerName(alias)
			end
		end
	end
end

function CommandBar:UnregisterCommand(name)
	local lower = trim(name):lower()
	if self.Commands[lower] then
		self.Commands[lower] = nil
		self.LastCommandArgs[lower] = nil
		return true
	end
	return false
end

function CommandBar:RemoveAlias(alias)
	local lower = trim(alias):lower()
	if self.Aliases[lower] then
		self.Aliases[lower] = nil
		return true
	end
	return false
end

function CommandBar:ClearVariables()
	clearTable(self.Variables)
end

function CommandBar:InitBuiltInCommands()
	self.BuiltInCommands = {
		["help"] = {
			Description = "Displays a list of all available commands.",
			Arguments = {},
			Aliases = { "?" },
			Function = function(_args)
				self:WriteLine("Operators:", Color3.fromRGB(255, 230, 100))
				self:WriteLine("\t;                  Separate statements", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t&&                 Chain if previous succeeded", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t||                 Chain if previous failed", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t!cmd               Repeat last command with same args", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t$Var = value       Set variable", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t$Var               Read variable", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t$$                 List all variables", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t2+2*3              Math (also usable in numeric args)", Color3.fromRGB(200, 200, 200))
				self:WriteLine("Player Selectors:", Color3.fromRGB(255, 230, 100))
				self:WriteLine("\tall, others, me, team/allies, enemies/nonteam,", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\tfriends, nonfriends, alive, dead", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t@user    Direct user (partial name ok)", Color3.fromRGB(200, 200, 200))
				self:WriteLine("\t,  +  -            Combine/include/exclude: all-me, team-me,bob", Color3.fromRGB(200, 200, 200))
				self:WriteLine("Available Commands:", Color3.fromRGB(255, 230, 100))
				local seen = {}
				for cmdName, cmd in pairs(self.BuiltInCommands) do
					if not seen[cmd] then
						seen[cmd] = true
						self:WriteLine(string.format("\t%s - %s", cmdName, cmd.Description or "No description provided."))
					end
				end
				if next(self.Commands) ~= nil then
					self:WriteLine("Custom Commands:", Color3.fromRGB(255, 230, 100))
					local seenCustom = {}
					for cmdName, cmd in pairs(self.Commands) do
						if not seenCustom[cmd] then
							seenCustom[cmd] = true
							self:WriteLine(string.format("\t%s - %s", cmdName, cmd.Description or "No description provided."))
						end
					end
				end
			end,
		},
		["manual"] = {
			Description = "Displays a manual on how to use a command.",
			Arguments = {
				["CommandName"] = { Name = "CommandName", Type = "string", Required = true, Index = 1 },
			},
			Aliases = { "man" },
			Function = function(args)
				local commandName = tostring(args["CommandName"]):lower()
				local command = self:__FindCommand(commandName)
				if not command then
					self:WriteLine("Command not found: " .. commandName, Color3.fromRGB(255, 100, 100))
					return
				end
				self:WriteLine("Manual - " .. commandName, Color3.fromRGB(255, 230, 100))
				self:WriteLine("Description: " .. (command.Description or "No description provided."))
				local syntaxParts = { commandName }
				local argList = {}
				if command.Arguments then
					local ordered = getOrderedArguments(command.Arguments)
					for _, item in ipairs(ordered) do
						local cfg = item.Config
						local displayLabel = cfg.Name or item.Key
						if cfg.Required then
							table.insert(syntaxParts, string.format("<%s>", displayLabel))
						else
							table.insert(syntaxParts, string.format("[%s]", displayLabel))
						end
						local defaultStr = "none"
						if cfg.Default ~= nil then
							defaultStr = tostring(cfg.Default)
						end
						local reqStr = "Optional"
						if cfg.Required then
							reqStr = "Required"
						end
						table.insert(argList, string.format("  - %s (%s) - %s (Default: %s)", displayLabel, cfg.Type or "string", reqStr, defaultStr))
					end
				end
				self:WriteLine("Usage: " .. table.concat(syntaxParts, " "), Color3.fromRGB(150, 200, 255))
				if #argList > 0 then
					self:WriteLine("Arguments:")
					for _, argLine in ipairs(argList) do
						self:WriteLine(argLine, Color3.fromRGB(200, 200, 200))
					end
				else
					self:WriteLine("Arguments: None")
				end
			end,
		},
		["clear"] = {
			Description = "Clears the console.",
			Arguments = {},
			Aliases = { "cls" },
			Function = function(_args)
				self:ClearOutput()
			end,
		},
		["echo"] = {
			Description = "Prints a string to the console.",
			Arguments = {
				["Text"] = { Name = "Text", Type = "string", Required = true, Default = "Hello world.", Index = 1 },
			},
			Function = function(args)
				self:WriteLine(tostring(args["Text"]))
			end,
		},
		["history"] = {
			Description = "Shows or clears command history.",
			Arguments = {
				["Action"] = { Name = "Action", Type = "string", Required = false, Default = "show", Index = 1 },
			},
			Function = function(args)
				local action = tostring(args["Action"] or "show"):lower()
				if action == "clear" or action == "cls" then
					clearTable(self.CmdHistory)
					self.HistoryIdx = 1
					self:WriteLine("History cleared.", Color3.fromRGB(100, 255, 100))
				else
					self:WriteLine("History:", Color3.fromRGB(255, 230, 100))
					if #self.CmdHistory == 0 then
						self:WriteLine("  (empty)", Color3.fromRGB(150, 150, 150))
					else
						for idx, line in ipairs(self.CmdHistory) do
							self:WriteLine(string.format("  %d: %s", idx, line), Color3.fromRGB(200, 200, 200))
						end
					end
				end
			end,
		},
	}
	for cmdName, cmd in pairs(self.BuiltInCommands) do
		local aliases = cmd.Aliases
		if aliases and type(aliases) == "table" then
			for _, alias in ipairs(aliases) do
				if type(alias) == "string" then
					self.BuiltInCommands[alias:lower()] = cmd
				end
			end
		end
	end
end

function CommandBar:Create()
    if CommandBar.ScreenGui then
        pcall(function() CommandBar.ScreenGui:Destroy() end)
        CommandBar.ScreenGui = nil
        CommandBar.MainFrame = nil
    end

    local Parent = nil
    pcall(function()
        if typeof(gethui) == "function" then
            Parent = gethui()
		end
    end)
    if Parent == nil then
        pcall(function() Parent = game:GetService("CoreGui") end)
    end
    if Parent == nil then
        local LocalPlayer = Players and Players.LocalPlayer
        if LocalPlayer then
            pcall(function() Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end)
            if Parent == nil then
                Parent = LocalPlayer.PlayerGui
            end
        end
    end

    CommandBar.ScreenGui = CommandBar:New("ScreenGui", {
        Name = (function() local str = ""; for _ = 1, 20 do str = str .. string.char(math.random(97, 122)) end return str end)(),
        Parent = Parent,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })

    CommandBar.MainFrame = CommandBar:New("Frame", {
        Parent = CommandBar.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(18,18,18),
        Position = UDim2.new(1,-366,1,-56),
        Size = UDim2.new(0, 350, 0, 40),
        Name = "Main",
        BackgroundTransparency = 0.15
    }, {
        CommandBar:New("UICorner"),
        CommandBar:New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.fromRGB(80,80,80),
			Transparency = 0.1
        }),
        CommandBar:MakeBlur()
    })

    CommandBar.NotificationHolder = CommandBar:New("Frame", {
        Parent = CommandBar.ScreenGui,
        Name = "Notifications",
        Size = UDim2.new(0, 330, 0, 400),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        BackgroundTransparency = 1
    }, {
        CommandBar:New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top
        })
    })

	CommandBar.Tooltip = CommandBar:New("TextLabel", {
		Parent = CommandBar.ScreenGui,
		Name ="Tooltip",
		BackgroundColor3 = Color3.fromRGB(18,18,18),
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(220,220,220),
		Visible = false,
        TextSize = 12,
	}, {
		CommandBar:New("UICorner"),
		CommandBar:MakeBlur(),
		CommandBar:New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(80,80,80)
		})
	})

	CommandBar.AutoComplete = CommandBar:New("CanvasGroup", {
		Parent = CommandBar.MainFrame,
		Name = "AutoComplete",
		BackgroundColor3 = Color3.fromRGB(18,18,18),
		BackgroundTransparency = 0.15,
		Position = UDim2.new(0, 40, 0, -8),
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.new(1, -48, 0, 0),
		Visible = false,
		GroupTransparency = 1
	}, {
		CommandBar:MakeBlur(),
		CommandBar:New("UICorner"),
		CommandBar:New("UISizeConstraint", {
			MaxSize = Vector2.new(302, 200),
		}),
		CommandBar:New("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8)
		}),
		CommandBar:New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(18,18,18),
			ScrollBarThickness = 2,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.None,
			Name = "List"
		}, {
			CommandBar:New("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top
			}),
		})
	})

    CommandBar:MakeDraggable(CommandBar:New("Frame", {
        Parent = CommandBar.MainFrame,
        Size = UDim2.new(0, 18, 1, 0),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        Name = "Drag"
    }, {
        CommandBar:New("ImageLabel", {
            Size = UDim2.new(0, 15, 0, 15),
            Position = UDim2.new(0.5, 1, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://137183678565296",
            Name = "Icon"
        })
    }), CommandBar.MainFrame)

    local SettingsButton = CommandBar:New("TextButton", {
        Parent = CommandBar.MainFrame,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(0, 19, 0, 19),
        Position = UDim2.new(1,-19,0,0),
        BackgroundTransparency = 1,
        Name = "Settings"
    }, {
        CommandBar:New("ImageLabel", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0.5, -1, 0.5, 1),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://73820177347303",
            Name = "Icon"
        })
    })
    local HelpButton = CommandBar:New("TextButton", {
        Parent = CommandBar.MainFrame,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(0, 19, 0, 19),
        Position = UDim2.new(1,-19,0, 19),
        BackgroundTransparency = 1,
        Name = "Help"
    }, {
        CommandBar:New("ImageLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -1, 0.5, 1),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://3523243755",
            Name = "Icon"
        })
    })

    local Input = CommandBar:New("TextBox", {
        Parent = CommandBar.MainFrame,
		Name = "Input",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(170, 170, 170),
        PlaceholderText = "help",
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12,
        ClearTextOnFocus = false,
        RichText = false,
    })
	
	do
        if CommandBar._acConn then
            pcall(function() CommandBar._acConn:Disconnect() end)
            CommandBar._acConn = nil
        end
        local List = CommandBar.AutoComplete:FindFirstChild("List")
        if not List then
            List = CommandBar.AutoComplete:WaitForChild("List")
        end
        local MaxItems = 20
        local Suggestions = {}
        local Selected = 1
        local TokenStart = 1
        local LastCursor = 1
        local CurrentIsFirst = true
        local CurrentApplicable = false
        local AcTweenIn = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local AcTweenOut = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local AcGen = 0
        local IdleDelay = 3
        local LastActivity = os.clock()
        local IdleDismissed = false

        local function getCursor()
            local ok, pos = pcall(function() return Input.CursorPosition end)
            if ok and type(pos) == "number" then
                return pos
            end
            return #Input.Text + 1
        end

        local function setCursor(pos)
            pcall(function()
                Input.CursorPosition = pos
            end)
        end

        local function getFullDesc(item, isFirst)
            local lookup = item
            if lookup:sub(1, 1) == "!" then
                lookup = lookup:sub(2)
            end
            local cmd = CommandBar:__FindCommand(lookup)
            if cmd and (isFirst or CommandBar:__IsCommandName(lookup)) then
                local desc = tostring(cmd.Description or "")
                if desc ~= "" then
                    return desc
                end
            end
            return nil
        end

        local function buildDisplay(item, isFirst)
            local desc = getFullDesc(item, isFirst)
            if desc then
                if #desc > 38 then
                    desc = desc:sub(1, 35) .. "..."
                end
                return item .. "   -   " .. desc
            end
            if not isFirst then
                local found = nil
                pcall(function()
                    for _, p in ipairs(Players:GetPlayers()) do
                        local nm = p.Name
                        local dp = p.DisplayName
                        if nm and (item == nm or item == "@" .. nm or item == dp) then
                            found = p
                            break
                        end
                    end
                end)
                if found then
                    local okName, disp = pcall(function() return found.DisplayName end)
                    if okName and type(disp) == "string" and disp ~= "" and disp ~= found.Name then
                        return "@" .. found.Name .. " (" .. disp .. ")"
                    end
                    return "@" .. found.Name
                end
            end
            return item
        end

        local RowHeight = 26
        local RowGap = 2
        local ChromeHeight = 16
        local MaxListHeight = 200

        local function pokeActivity()
            LastActivity = os.clock()
            IdleDismissed = false
        end

        local function hide()
            local ac = CommandBar.AutoComplete
            if not ac or not ac.Visible then
                return
            end
            AcGen = AcGen + 1
            local gen = AcGen
            local twOk, tw = pcall(function()
                return TweenService:Create(ac, AcTweenOut, {
                    GroupTransparency = 1,
                    Size = UDim2.new(1, -48, 0, 0),
                })
            end)
            if not twOk or not tw then
                pcall(function() ac.Visible = false end)
                return
            end
            tw.Completed:Connect(function()
                if gen == AcGen and CommandBar.AutoComplete == ac then
                    pcall(function() ac.Visible = false end)
                end
            end)
            pcall(function() tw:Play() end)
        end

        local function show(targetH)
            local ac = CommandBar.AutoComplete
            if not ac then
                return
            end
            AcGen = AcGen + 1
            ac.Visible = true
            local props = { GroupTransparency = 0 }
            if targetH then
                props.Size = UDim2.new(1, -48, 0, targetH)
            end
            local twOk, tw = pcall(function()
                return TweenService:Create(ac, AcTweenIn, props)
            end)
            if twOk and tw then
                pcall(function() tw:Play() end)
            else
                pcall(function()
                    ac.GroupTransparency = 0
                    if targetH then
                        ac.Size = UDim2.new(1, -48, 0, targetH)
                    end
                end)
            end
        end

        local refresh

        local function rowUnderMouse()
            local mOk, m = pcall(function()
                return UserInputService:GetMouseLocation()
            end)
            if not mOk or not m then
                return nil
            end
            for _, child in ipairs(List:GetChildren()) do
                if child:IsA("TextButton") then
                    local pOk, pos = pcall(function() return child.AbsolutePosition end)
                    local sOk, size = pcall(function() return child.AbsoluteSize end)
                    if pOk and sOk and pos and size then
                        if m.X >= pos.X and m.X <= pos.X + size.X and m.Y >= pos.Y and m.Y <= pos.Y + size.Y then
                            return child.LayoutOrder
                        end
                    end
                end
            end
            return nil
        end

        local function render(resetScroll)
            if resetScroll then
                local hovered = rowUnderMouse()
                if hovered and Suggestions[hovered] then
                    Selected = hovered
                end
            end
            for _, child in ipairs(List:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            if #Suggestions == 0 then
                hide()
                return
            end
            local count = #Suggestions
            if count > MaxItems then count = MaxItems end
            local rowFullText = {}
            for i = 1, count do
                local item = Suggestions[i]
                local full = getFullDesc(item, CurrentIsFirst)
                if full and #full > 38 then
                    rowFullText[i] = full
                end
                local btn = CommandBar:New("TextButton", {
                    Name = "Suggestion" .. tostring(i),
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Color3.fromRGB(55, 55, 55),
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(170, 170, 170),
                    Text = buildDisplay(item, CurrentIsFirst),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    AutoButtonColor = false,
                    LayoutOrder = i,
                }, {
                    CommandBar:New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    CommandBar:New("UIPadding", {
                        PaddingLeft = UDim.new(0, 6),
                        PaddingRight = UDim.new(0, 6),
                    }),
                })
                if i == Selected then
                    btn.BackgroundTransparency = 0
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                local idx = i
                btn.MouseEnter:Connect(function()
                    pokeActivity()
                    Selected = idx
                    for _, other in ipairs(List:GetChildren()) do
                        if other:IsA("TextButton") then
                            local order = other.LayoutOrder
                            if order == Selected then
                                other.BackgroundTransparency = 0
                                other.TextColor3 = Color3.fromRGB(255, 255, 255)
                            else
                                other.BackgroundTransparency = 1
                                other.TextColor3 = Color3.fromRGB(170, 170, 170)
                            end
                        end
                    end
                    local full = rowFullText[idx]
                    if full then
                        pcall(function() CommandBar:AddTooltip(btn, full) end)
                    end
                end)
                btn.Parent = List
            end
            local contentH = count * RowHeight + math.max(count - 1, 0) * RowGap
            pcall(function()
                List.CanvasSize = UDim2.new(0, 0, 0, contentH)
            end)
            if resetScroll then
                pcall(function()
                    List.CanvasPosition = Vector2.new(0, 0)
                end)
            end
            local targetH = contentH + ChromeHeight
            if targetH > MaxListHeight then
                targetH = MaxListHeight
            end
            show(targetH)
        end

        refresh = function(resetSelection)
            local cursor = getCursor()
            LastCursor = cursor
            local result = CommandBar:GetSuggestions(Input.Text, cursor)
            TokenStart = result.TokenStart
            CurrentIsFirst = result.IsFirst
            CurrentApplicable = result.Applicable or false
            Suggestions = {}
            for i, v in ipairs(result.Items) do
                if i > MaxItems then break end
                table.insert(Suggestions, v)
            end
            if result.Token == "" then
                local beforeCursor = Input.Text:sub(1, math.max(cursor - 1, 0))
                if trim(beforeCursor) == "" then
                    Suggestions = {}
                end
            end
            if resetSelection then
                Selected = 1
            else
                if Selected < 1 then Selected = 1 end
                if #Suggestions > 0 and Selected > #Suggestions then
                    Selected = #Suggestions
                end
            end
            render(true)
        end

        local function applySelected()
            if not CurrentApplicable then return end
            local comp = Suggestions[Selected]
            if not comp then return end
            local newText, newCursor = CommandBar:ApplyCompletion(Input.Text, getCursor(), TokenStart, comp)
            Input.Text = newText
            setCursor(newCursor)
            pcall(function() Input:CaptureFocus() end)
            refresh(false)
        end

        local function historyStep(direction)
            local entry = CommandBar:__GetHistory(direction)
            if entry ~= nil then
                Input.Text = entry
                setCursor(#entry + 1)
            end
        end

        local function showAllCommands()
            local cursor = getCursor()
            local result = CommandBar:GetSuggestions(Input.Text, cursor)
            if result.Token ~= "" or not result.IsFirst then
                return
            end
            if #result.Items == 0 then
                return
            end
            TokenStart = result.TokenStart
            LastCursor = cursor
            CurrentIsFirst = result.IsFirst
            CurrentApplicable = true
            Suggestions = {}
            for i, v in ipairs(result.Items) do
                if i > MaxItems then break end
                table.insert(Suggestions, v)
            end
            Selected = 1
            render(true)
        end

        CommandBar._acGen = (CommandBar._acGen or 0) + 1
        local myGen = CommandBar._acGen
        task.spawn(function()
            while myGen == CommandBar._acGen do
                task.wait(0.25)
                if myGen ~= CommandBar._acGen then
                    return
                end
                local ac = CommandBar.AutoComplete
                if not ac or not Input or not Input.Parent then
                    return
                end
                local ok, focused = pcall(function() return Input:IsFocused() end)
                if ok and focused and not IdleDismissed and #Suggestions == 0 and (os.clock() - LastActivity) >= IdleDelay then
                    showAllCommands()
                end
            end
        end)

        Input:GetPropertyChangedSignal("Text"):Connect(function()
            local ok, focused = pcall(function() return Input:IsFocused() end)
            if ok and focused then
                pokeActivity()
                refresh(true)
            end
        end)
        Input:GetPropertyChangedSignal("CursorPosition"):Connect(function()
            local ok, focused = pcall(function() return Input:IsFocused() end)
            if ok and focused then
                local cursor = getCursor()
                if cursor == LastCursor then
                    return
                end
                pokeActivity()
                refresh(false)
            end
        end)
        Input.Focused:Connect(function()
            pokeActivity()
            refresh(true)
        end)

        CommandBar._acConn = UserInputService.InputBegan:Connect(function(KeyInput, _gpe)
            local ok, focused = pcall(function() return Input:IsFocused() end)
            if not (ok and focused) then
                return
            end
            pokeActivity()
            local code = KeyInput.KeyCode
            if code == Enum.KeyCode.Tab then
                if CommandBar.AutoComplete.Visible and #Suggestions > 0 then
                    applySelected()
                end
            elseif code == Enum.KeyCode.Up then
                if CommandBar.AutoComplete.Visible and #Suggestions > 0 then
                    Selected = Selected - 1
                    if Selected < 1 then Selected = #Suggestions end
                    render(false)
                    local saved = LastCursor
                    pcall(function() task.defer(function() setCursor(saved) end) end)
                else
                    historyStep("Up")
                end
            elseif code == Enum.KeyCode.Down then
                if CommandBar.AutoComplete.Visible and #Suggestions > 0 then
                    Selected = Selected + 1
                    if Selected > #Suggestions then Selected = 1 end
                    render(false)
                    local saved = LastCursor
                    pcall(function() task.defer(function() setCursor(saved) end) end)
                else
                    historyStep("Down")
                end
            elseif code == Enum.KeyCode.Escape then
                IdleDismissed = true
                hide()
            end
        end)

        Input.FocusLost:Connect(function(EnterPressed)
            hide()
            if not EnterPressed then
                return
            end

            local Raw = Input.Text
            Input.Text = ""
            CommandBar:ExecuteString(Raw)
        end)
    end

    SettingsButton.MouseButton1Click:Connect(function()
        CommandBar:ExecuteString("settings")
    end)

    HelpButton.MouseButton1Click:Connect(function()
        CommandBar:ExecuteString("help")
    end)

end

function CommandBar:Notify(Title, Content, Duration)
    if not CommandBar.NotificationHolder then return end

    local TitleSize = CommandBar:GetTextBounds(Title or "Placeholder Title", 18, Font.fromEnum(Enum.Font.SourceSans), CommandBar.NotificationHolder.AbsoluteSize.X - 40)
    local TextSize = CommandBar:GetTextBounds(Content or "Placeholder Text", 18, Font.fromEnum(Enum.Font.SourceSans), CommandBar.NotificationHolder.AbsoluteSize.X - 16)

    local TitleHeight = 22 > TitleSize.Y and 22 or TitleSize.Y + 6
    local ContentHeight = 30 > TextSize.Y and 30 or TextSize.Y + 4

    local BaseBackgroundTransparency = 0.2
    local HoverBackgroundTransparency = 0.08

    local NotificationFrame = CommandBar:New("CanvasGroup", {
        Parent = CommandBar.NotificationHolder,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Name = (function() local str = ""; for _ = 1, 20 do str = str .. string.char(math.random(97, 122)) end; return str end)(),
        BackgroundColor3 = Color3.fromRGB(18,18,18),
        BackgroundTransparency = BaseBackgroundTransparency

    }, {
        CommandBar:New("UICorner", {
            BottomLeftRadius = UDim.new(0, 12),
            BottomRightRadius = UDim.new(0, 4),
            TopLeftRadius = UDim.new(0, 4),
            TopRightRadius = UDim.new(0, 12),
        }),
		CommandBar:New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.fromRGB(80,80,80),
			Transparency = 0.1
        }),
        CommandBar:New("TextLabel", {
            Name = "Title",
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -40, 0, TitleHeight),
            BackgroundTransparency = 1,
            TextTransparency = 0,
            TextColor3 = Color3.fromRGB(220,220,220),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
			RichText = true,
            FontFace = Font.fromEnum(Enum.Font.SourceSans),
            TextSize = 18,
            Text = Title or "Placeholder Title"
        }),
        CommandBar:New("TextLabel", {
            Name = "Content",
            Position = UDim2.new(0, 8, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(1, -16, 0, ContentHeight),
            BackgroundTransparency = 1,
            TextTransparency = 0,
            TextColor3 = Color3.fromRGB(220,220,220),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
			RichText = true,
            FontFace = Font.fromEnum(Enum.Font.SourceSans),
            TextSize = 18,
            Text = Content or "Placeholder Text"
        }),
        CommandBar:New("TextButton", {
            Name = "Close",
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -20, 0, 0),
            BackgroundTransparency = 1
        }, {
            CommandBar:New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5,0.5),
                Name = "Icon",
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                Image = "rbxassetid://121816018671466"
            })
        }),
        CommandBar:MakeBlur()
    })

    local TitleLabel = NotificationFrame:FindFirstChild("Title")
    local ContentLabel = NotificationFrame:FindFirstChild("Content")
    local CloseButton = NotificationFrame:FindFirstChild("Close")

    local Closed = false
    local Hovered = false

    local function CloseNotification()
        if Closed then return end
        Closed = true

        if not NotificationFrame or not NotificationFrame.Parent then return end

        if CloseButton then
            CloseButton.Active = false
        end

        local tween = TweenService:Create(NotificationFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            GroupTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0)
        })

        if TitleLabel then
            TweenService:Create(TitleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        end
        if ContentLabel then
            TweenService:Create(ContentLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        end

        tween:Play()
        tween.Completed:Wait()
        if NotificationFrame then
            NotificationFrame:Destroy()
        end
    end

    if CloseButton then
        CloseButton.MouseButton1Click:Connect(function()
            task.spawn(CloseNotification)
        end)
    end

    NotificationFrame.MouseEnter:Connect(function()
        Hovered = true
        TweenService:Create(NotificationFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = HoverBackgroundTransparency
        }):Play()
    end)

    NotificationFrame.MouseLeave:Connect(function()
        Hovered = false
        TweenService:Create(NotificationFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = BaseBackgroundTransparency
        }):Play()
    end)

    TweenService:Create(NotificationFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        GroupTransparency = 0,
        Size = UDim2.new(1, 0, 0, TitleHeight + ContentHeight)
    }):Play()

    task.spawn(function()
        local Remaining = (Duration or 3) + 0.15

        while Remaining > 0 do
            if Closed then return end
            local dt = task.wait()
            Remaining = Remaining - (Hovered and dt * 0.5 or dt)
        end

        CloseNotification()
    end)
end

function CommandBar:Destroy()

	for _, Func in pairs(CommandBar.UnloadCallbacks) do
		if typeof(Func) == "function" then
			Func()
		end
	end 

    if CommandBar._acConn then
        pcall(function() CommandBar._acConn:Disconnect() end)
        CommandBar._acConn = nil
    end
    CommandBar._acGen = (CommandBar._acGen or 0) + 1
    if CommandBar.ScreenGui then CommandBar.ScreenGui:Destroy() end
    CommandBar.ScreenGui = nil
    CommandBar.MainFrame = nil
    CommandBar.AutoComplete = nil
end

function CommandBar:AddUnloadCallback(func)
	table.insert(CommandBar.UnloadCallbacks, func)
end


TextChatService.SendingMessage:Connect(function(Message)
    if #Message.Text > 1 and Message.Text:sub(1,1) == CommandBar.Prefix then
        CommandBar:ExecuteString(Message.Text:sub(2,#Message.Text) or "", true)
    end
end)

function CommandBar:CreateMenu(Title)
	if not CommandBar.ScreenGui then
		warn("CreateMenu: call CommandBar:Create() first.")
		return nil
	end

	local Menu = {}
	Menu._controls = {}
	Menu._order = 0

	local Accent = Color3.fromRGB(0, 120, 255)
	local Bg = Color3.fromRGB(18, 18, 18)
	local Fg = Color3.fromRGB(220, 220, 220)
	local Dim = Color3.fromRGB(140, 140, 140)
	local RowBg = Color3.fromRGB(40, 40, 40)
	local OffBg = Color3.fromRGB(60, 60, 60)
	local Stroke = Color3.fromRGB(80, 80, 80)
	local MenuFont = Font.fromEnum(Enum.Font.SourceSans)

	local function nextOrder()
		Menu._order = Menu._order + 1
		return Menu._order
	end

	local Window = CommandBar:New("Frame", {
		Parent = CommandBar.ScreenGui,
		Name = "Menu",
		BackgroundColor3 = Bg,
		BackgroundTransparency = 0.15,
		Position = UDim2.new(0.5, -150, 0.5, -190),
		Size = UDim2.new(0, 300, 0, 380),
		Visible = false,
	}, {
		CommandBar:New("UICorner", {CornerRadius = UDim.new(0, 8)}),
		CommandBar:New("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Stroke}),
		CommandBar:MakeBlur(),
	})

	local TitleBar = CommandBar:New("TextButton", {
		Parent = Window,
		Name = "TitleBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		AutoButtonColor = false,
	}, {
		CommandBar:New("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -48, 1, 0),
			FontFace = MenuFont,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Fg,
			Text = Title or "Menu",
		}),
		CommandBar:New("TextButton", {
			Name = "Close",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.new(0, 22, 0, 22),
			Text = "",
			AutoButtonColor = false,
		}, {
			CommandBar:New("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18),
				BackgroundTransparency = 1,
				Image = "rbxassetid://121816018671466",
			}),
		}),
	})
	CommandBar:MakeDraggable(TitleBar, Window)
	TitleBar.Close.MouseButton1Click:Connect(function()
		Window.Visible = false
	end)

	local Content = CommandBar:New("ScrollingFrame", {
		Parent = Window,
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 40),
		Size = UDim2.new(1, -20, 1, -48),
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, {
		CommandBar:New("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		CommandBar:New("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		}),
	})

	function Menu:SetVisible(v)
		Window.Visible = v and true or false
	end
	function Menu:IsVisible()
		return Window.Visible
	end
	function Menu:Toggle()
		Window.Visible = not Window.Visible
	end
	function Menu:Destroy()
		pcall(function() Window:Destroy() end)
	end

	function Menu:Section(Name)
		local Section = {}
		CommandBar:New("TextLabel", {
			Parent = Content,
			Name = "Section",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = nextOrder(),
			FontFace = MenuFont,
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Accent,
			Text = tostring(Name),
		})
		CommandBar:New("Frame", {
			Parent = Content,
			Name = "Divider",
			BackgroundColor3 = OffBg,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			LayoutOrder = nextOrder(),
		})

		function Section:Toggle(Config)
			Config = Config or {}
			local State = Config.Default == true
			local Row = CommandBar:New("Frame", {
				Parent = Content,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = nextOrder(),
			}, {
				CommandBar:New("TextLabel", {
					Name = "Name",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -50, 1, 0),
					FontFace = MenuFont,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Fg,
					Text = Config.Name or "Toggle",
				}),
				CommandBar:New("TextButton", {
					Name = "Switch",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 40, 0, 20),
					AutoButtonColor = false,
					Text = "",
					BackgroundColor3 = State and Accent or OffBg,
				}, {
					CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					CommandBar:New("Frame", {
						Name = "Knob",
						AnchorPoint = Vector2.new(0, 0.5),
						Size = UDim2.new(0, 15, 0, 15),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
					}, {
						CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					}),
				}),
			})
			local Switch = Row:FindFirstChild("Switch")
			local Knob = Switch:FindFirstChild("Knob")
			local function paint()
				Switch.BackgroundColor3 = State and Accent or OffBg
				Knob.Position = State and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
			end
			local Ctrl = {}
			function Ctrl:Set(v)
				State = v and true or false
				paint()
				if type(Config.Callback) == "function" then
					Config.Callback(State)
				end
			end
			function Ctrl:Get()
				return State
			end
			Switch.MouseButton1Click:Connect(function()
				Ctrl:Set(not State)
			end)
			paint()
			table.insert(Menu._controls, Ctrl)
			return Ctrl
		end

		function Section:Slider(Config)
			Config = Config or {}
			local Min = Config.Min or 0
			local Max = Config.Max or 100
			local Inc = Config.Increment or 1
			local Suffix = Config.Suffix or ""
			local Value = Config.Default ~= nil and Config.Default or Min
			local Row = CommandBar:New("Frame", {
				Parent = Content,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				LayoutOrder = nextOrder(),
			}, {
				CommandBar:New("TextLabel", {
					Name = "Name",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, -70, 0, 20),
					FontFace = MenuFont,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Fg,
					Text = Config.Name or "Slider",
				}),
				CommandBar:New("TextLabel", {
					Name = "Value",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0, 70, 0, 20),
					FontFace = MenuFont,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = Dim,
					Text = "",
				}),
				CommandBar:New("TextButton", {
					Name = "Bar",
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 7, 1, -6),
					Size = UDim2.new(1, -14, 0, 7),
					AutoButtonColor = false,
					Text = "",
					BackgroundColor3 = OffBg,
				}, {
					CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					CommandBar:New("Frame", {
						Name = "Fill",
						BackgroundColor3 = Accent,
						BorderSizePixel = 0,
						Size = UDim2.new(0, 0, 1, 0),
					}, {
						CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					}),
					CommandBar:New("Frame", {
						Name = "Knob",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0, 12, 0, 12),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
					}, {
						CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					}),
				}),
			})
			local ValueLabel = Row:FindFirstChild("Value")
			local Bar = Row:FindFirstChild("Bar")
			local Fill = Bar:FindFirstChild("Fill")
			local Knob = Bar:FindFirstChild("Knob")
			local Dragging = false
			local function ratio()
				if Max <= Min then return 0 end
				return math.clamp((Value - Min) / (Max - Min), 0, 1)
			end
			local function paint()
				local r = ratio()
				Fill.Size = UDim2.new(r, 0, 1, 0)
				Knob.Position = UDim2.new(r, 0, 0.5, 0)
				ValueLabel.Text = tostring(Value) .. Suffix
			end
			local function apply(v, fire)
				Value = math.clamp(v, Min, Max)
				paint()
				if fire and type(Config.Callback) == "function" then
					Config.Callback(Value)
				end
			end
			local function fromX(x)
				local pos = Bar.AbsolutePosition.X
				local size = Bar.AbsoluteSize.X
				if size <= 0 then return end
				local r = math.clamp((x - pos) / size, 0, 1)
				apply(Min + math.floor((r * (Max - Min)) / Inc + 0.5) * Inc, true)
			end
			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
					fromX(input.Position.X)
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							Dragging = false
						end
					end)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if not Dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					fromX(input.Position.X)
				end
			end)
			local Ctrl = {}
			function Ctrl:Set(v)
				apply(tonumber(v) or Value, true)
			end
			function Ctrl:Get()
				return Value
			end
			apply(Value, false)
			table.insert(Menu._controls, Ctrl)
			return Ctrl
		end

		function Section:RangeSlider(Config)
			Config = Config or {}
			local Min = Config.Min or 0
			local Max = Config.Max or 100
			local Inc = Config.Increment or 1
			local Suffix = Config.Suffix or ""
			local Def = Config.Default or {Min, Max}
			local Lo = math.clamp(tonumber(Def[1]) or Min, Min, Max - 1)
			local Hi = math.clamp(tonumber(Def[2]) or Max, Lo + 1, Max)
			local Row = CommandBar:New("Frame", {
				Parent = Content,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				LayoutOrder = nextOrder(),
			}, {
				CommandBar:New("TextLabel", {
					Name = "Name",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, -90, 0, 20),
					FontFace = MenuFont,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Fg,
					Text = Config.Name or "Range",
				}),
				CommandBar:New("TextLabel", {
					Name = "Value",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0, 90, 0, 20),
					FontFace = MenuFont,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = Dim,
					Text = "",
				}),
				CommandBar:New("TextButton", {
					Name = "Bar",
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 7, 1, -6),
					Size = UDim2.new(1, -14, 0, 7),
					AutoButtonColor = false,
					Text = "",
					BackgroundColor3 = OffBg,
				}, {
					CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					CommandBar:New("Frame", {
						Name = "Fill",
						BackgroundColor3 = Accent,
						BorderSizePixel = 0,
						Size = UDim2.new(0, 0, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
					}, {
						CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					}),
					CommandBar:New("Frame", {
						Name = "LoKnob",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0, 12, 0, 12),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
					}, {
						CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					}),
					CommandBar:New("Frame", {
						Name = "HiKnob",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0, 12, 0, 12),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
					}, {
						CommandBar:New("UICorner", {CornerRadius = UDim.new(1, 0)}),
					}),
				}),
			})
			local ValueLabel = Row:FindFirstChild("Value")
			local Bar = Row:FindFirstChild("Bar")
			local Fill = Bar:FindFirstChild("Fill")
			local LoKnob = Bar:FindFirstChild("LoKnob")
			local HiKnob = Bar:FindFirstChild("HiKnob")
			local Dragging = nil
			local function snap(v)
				return math.clamp(Min + math.floor((v - Min) / Inc + 0.5) * Inc, Min, Max)
			end
			local function ratio(v)
				if Max <= Min then return 0 end
				return math.clamp((v - Min) / (Max - Min), 0, 1)
			end
			local function paint()
				local rLo, rHi = ratio(Lo), ratio(Hi)
				Fill.Position = UDim2.new(rLo, 0, 0, 0)
				Fill.Size = UDim2.new(rHi - rLo, 0, 1, 0)
				LoKnob.Position = UDim2.new(rLo, 0, 0.5, 0)
				HiKnob.Position = UDim2.new(rHi, 0, 0.5, 0)
				ValueLabel.Text = tostring(Lo) .. " - " .. tostring(Hi) .. Suffix
			end
			local function fire()
				if type(Config.Callback) == "function" then
					Config.Callback(Lo, Hi)
				end
			end
			local function fromX(x, which)
				local pos = Bar.AbsolutePosition.X
				local size = Bar.AbsoluteSize.X
				if size <= 0 then return end
				local v = snap(Min + math.clamp((x - pos) / size, 0, 1) * (Max - Min))
				if which == "lo" then
					Lo = math.clamp(v, Min, Hi - 1)
				elseif which == "hi" then
					Hi = math.clamp(v, Lo + 1, Max)
				else
					local dLo = math.abs(v - Lo)
					local dHi = math.abs(v - Hi)
					if dLo <= dHi then
						Lo = math.clamp(v, Min, Hi - 1)
					else
						Hi = math.clamp(v, Lo + 1, Max)
					end
				end
				paint()
				fire()
			end
			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local pos = Bar.AbsolutePosition.X
					local size = Bar.AbsoluteSize.X
					local r = size > 0 and math.clamp((input.Position.X - pos) / size, 0, 1) or 0
					local rLo = ratio(Lo)
					local rHi = ratio(Hi)
					Dragging = math.abs(r - rLo) <= math.abs(r - rHi) and "lo" or "hi"
					fromX(input.Position.X, Dragging)
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							Dragging = nil
						end
					end)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if not Dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					fromX(input.Position.X, Dragging)
				end
			end)
			local Ctrl = {}
			function Ctrl:Set(lo, hi)
				if lo ~= nil then Lo = math.clamp(tonumber(lo) or Lo, Min, Max - 1) end
				if hi ~= nil then Hi = math.clamp(tonumber(hi) or Hi, Lo + 1, Max) end
				paint()
				fire()
			end
			function Ctrl:Get()
				return Lo, Hi
			end
			paint()
			table.insert(Menu._controls, Ctrl)
			return Ctrl
		end

		function Section:Dropdown(Config)
			Config = Config or {}
			local Items = Config.Items or {}
			local Current = Config.Default or Items[1]
			local Row = CommandBar:New("Frame", {
				Parent = Content,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = nextOrder(),
			}, {
				CommandBar:New("TextLabel", {
					Name = "Name",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -140, 1, 0),
					FontFace = MenuFont,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Fg,
					Text = Config.Name or "Dropdown",
				}),
				CommandBar:New("TextButton", {
					Name = "Pick",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 130, 0, 24),
					AutoButtonColor = false,
					FontFace = MenuFont,
					TextSize = 13,
					TextColor3 = Fg,
					BackgroundColor3 = RowBg,
					Text = tostring(Current),
				}, {
					CommandBar:New("UICorner", {CornerRadius = UDim.new(0, 6)}),
				}),
			})
			local Pick = Row:FindFirstChild("Pick")
			local Ctrl = {}
			function Ctrl:Set(v)
				for _, item in ipairs(Items) do
					if item == v then
						Current = item
						Pick.Text = tostring(Current)
						if type(Config.Callback) == "function" then
							Config.Callback(Current)
						end
						return
					end
				end
			end
			function Ctrl:Get()
				return Current
			end
			Pick.MouseButton1Click:Connect(function()
				if #Items == 0 then return end
				local idx = 1
				for i, item in ipairs(Items) do
					if item == Current then
						idx = i
						break
					end
				end
				Ctrl:Set(Items[(idx % #Items) + 1])
			end)
			Pick.Text = tostring(Current)
			table.insert(Menu._controls, Ctrl)
			return Ctrl
		end

		function Section:Button(Config)
			Config = Config or {}
			local Btn = CommandBar:New("TextButton", {
				Parent = Content,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = nextOrder(),
				AutoButtonColor = false,
				FontFace = MenuFont,
				TextSize = 14,
				TextColor3 = Fg,
				BackgroundColor3 = RowBg,
				Text = Config.Name or "Button",
			}, {
				CommandBar:New("UICorner", {CornerRadius = UDim.new(0, 6)}),
			})
			Btn.MouseButton1Click:Connect(function()
				if type(Config.Callback) == "function" then
					Config.Callback()
				end
			end)
			local Ctrl = {}
			function Ctrl:Press()
				if type(Config.Callback) == "function" then
					Config.Callback()
				end
			end
			table.insert(Menu._controls, Ctrl)
			return Ctrl
		end

		return Section
	end

	return Menu
end



return CommandBar
