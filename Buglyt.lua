
-- Buglyt.lua

--[[


  :      '-
  |_ \ / |_
      /

Let me know if you have any suggestions!


     ~ ~ ~ Listing ~ ~ ~

prettyFmt(val, ?name)

	Format value nicely, optionally provide name tag


prettyPrint(val, ?name)

	== print(prettyFmt(val, ?name))


runTests(function to test, tests, time, shortcircuit)

	Tests are { {args, correct output} }. Upon first failure: break if shortcircuit == true.
	 Keep function times if time == true.

printTestResults(test results, settings)
	
	Print the test results. The valid settings are, and the default is:
		{
		 result   = true/false, -- pass or failed test
		 time     = true/false, -- 
		 time     = true/false,
		 expected = true/false
		}


setTimerFn(function)

	Set what Buglyt uses internally to get current time. Should return a number. Default is os.clock


setGlobalNilIndex(function)

	Set what happens when you try to index a nil variable. Example:

		print(xaoiwdjao)

		Default:
		>> nil

		Buglyt.setGlobalNilIndex(Buglyt.errorNilIndex)
		>> error: Error: nil index: xaoiwdjao

		Buglyt.setGlobalNilIndex(Buglyt.warnNilIndex)
		>> Warning: nil index: xaoiwdjao

 timeFn(function, arguments...)

	Return time for function(arguments)

 timeRepsFn(repetitions, function, arguments...)

 	Return time for n repetitions of function(arguments...)

 comparePerformance(reps, functions, arguments...)

 	Map over a table of functions by table[key] = timeRepsFn(f, arguments)
 	 - Print results with prettyPrint

]]

local Buglyt = {}

local nowtime = os.clock

function Buglyt.setTimerFn(fn) nowtime = fn; end


-- utils
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

function Buglyt.prettyFmt(value, tag)
	if type(value) == "table" then
		return ( tag and tag or tostring(value) ) .. " = " .. prettyTableFormat(value)
	elseif type(value) == "function" then
		return tag and tag or tostring(value)
	else
		return ( tag and tag or type(value) ) .. ": ", tostring(value)
	end
end

function Buglyt.prettyPrint(value, tag) print(Buglyt.prettyFmt(value, tag)); end


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


-- testing
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


-- profiling
function Buglyt.timeFn(fn, ...)
	local start = nowtime()
	local ret = fn(...)
	return nowtime() - start, ret
end

function Buglyt.timeRepsFn(reps, fn, ...)
	local start = nowtime()
	for i = 1, reps do
		fn(...)
	end
	local elapsed = nowtime() - start
	return elapsed, elapsed / reps
end


--[[ Example

Buglyt.prettyPrint( Buglyt.comparePerformance(1e2,
{
	forloop = function(x)
		for i = 1, x do

		end
	end,
	whileloop = function(x)
		local i = 1
		while i < x do
			i = i + 1
		end
	end,
	untilloop = function(x)
		local i = 1
		repeat
			i = i + 1
		until i > x
	end
}, 100000), "Loop time comparison" )

]]
function Buglyt.comparePerformance(reps, fns, ...)
	for name, fn in pairs(fns) do
		fns[name] = Buglyt.timeRepsFn(reps, fn, ...)
	end
	return fns
end



return Buglyt
