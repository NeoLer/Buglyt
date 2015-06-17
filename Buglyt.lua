
-- Buglyt.lua

--[[
  Planned:
  
  - Document/tutorial
  - Redo tests
  - Profiling (probably too much of a performance fuckup implemented in pure Lua but we'll see)
  
]]

local Buglyt = {}


local function prettyTableFormat(t, indent)
	indent = indent and indent or 1
	local str = "{"
	for k, v in pairs(t) do
		if type(v) == "table" then
			str = str .. "\n" .. (" "):rep(indent) .. tostring(k) .. " = " .. prettyTableFormat(v, indent + 1)
		else
			str = str .. "\n" .. (" "):rep(indent) .. tostring(k) .. " = " .. tostring(v)
		end
	end
	return str .. "\n" .. (" "):rep(indent-1) .. "}"
end

function Buglyt.printPretty(value, tag)
	if type(value) == "table" then
		print((tag and tag or tostring(value)) .. " = " .. prettyTableFormat(value))
	elseif type(value) == "function" then
		print((tag and tag or tostring(value)))
	else
		print(tag .. ": ", tostring(value))
	end
end

function Buglyt.timeFn(fn, ...)
	local start = os.clock()
	local ret = fn(...)
	return os.clock()-start, ret
end

function Buglyt.runTests(fn, tests, time, shortcircuit)
	local results = { }
	local ret;
	for i = 1, #tests do
		local input, expected = tests[i][1], tests[i][2]
		if time then
			time, ret = Buglyt.timeFn(fn, unpack(input))
		else
			ret = fn(unpack(input))
		end
		if ret == unpack(expected) then
			results[#results + 1] = {
				result = "Pass",
				input = input,
				ret = ret,
				expected = expected,
				time = time and time or nil,
			}
		else
			results[#results + 1] = {
				result = "Failed",
				input = input,
				ret = ret,
				expected = expected,
				time = time and time or nil,
			}
			if shortcircuit then break end
		end
	end
	return results
end

function Buglyt.printTestResults(results, settings)
	for i = 1, #results do
		for setting, enabled in pairs(settings) do
			if enabled then
				if type(results[i][setting]) == "table" then
					io.write(setting .. ": ", results[i][setting])
				end
			end
		end
	end
end


local old_index;
local global_mt;


function Buglyt.warnNilIndex(t, index)
	print("Warning: nil index: " .. index)
end

function Buglyt.errorNilIndex(t, index)
	error("Error: nil index: " .. index)
end


function Buglyt.setGlobalNilIndex(fn)
	if not getmetatable(_G) then
		setmetatable(_G, {})
		global_mt = getmetatable(_G)
	end

	if global_mt._index then
		old_index = global_mt._index
		global_mt.__index = function(t, index)
			old_index(t, index)
			fn(t, index)
		end
	else
		global_mt.__index = fn
	end
end
