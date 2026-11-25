return function(L)
	local library = L.library
	local langLookup, langHooks, currentLang = {}, {}, "en"
	local entries, nameToCode = {}, {}
	library.Languages = {}

	local function indexText(t, entry)
		if type(t) ~= "string" then return end
		langLookup[t] = langLookup[t] or {e = entry, up = false}
		local u = string.upper(t)
		langLookup[u] = langLookup[u] or {e = entry, up = true}
	end

	function library:registerLanguage(code, name, strings)
		if not nameToCode[name] then table.insert(library.Languages, name) end
		nameToCode[name] = code
		for _, t in ipairs(strings or {}) do
			local en, tr = t[1], t[2]
			if type(en) == "string" and type(tr) == "string" then
				local e = entries[en] or {en = en}
				entries[en] = e
				e[code] = tr
				indexText(en, e)
				indexText(tr, e)
			end
		end
	end

	function library:tr(text)
		if type(text) ~= "string" then return text end
		local hit = langLookup[text]
		if not hit then return text end
		local out = hit.e[currentLang] or hit.e.en or text
		return hit.up and string.upper(out) or out
	end

	function library:getLanguage() return currentLang end
	function library:onLanguage(fn) table.insert(langHooks, fn) end

	function library:setLanguage(name)
		local code = nameToCode[name]
		if not code then return end
		currentLang = code
		for _, obj in ipairs(self.screen:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				local t = self:tr(obj.Text)
				if t ~= obj.Text then obj.Text = t end
			elseif obj:IsA("TextBox") then
				local t = self:tr(obj.PlaceholderText)
				if t ~= obj.PlaceholderText then obj.PlaceholderText = t end
			end
		end
		for _, hook in ipairs(langHooks) do pcall(hook, code) end
	end
end