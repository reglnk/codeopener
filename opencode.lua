#!/bin/lua

--[==============[

The MIT License (MIT)

Copyright (c) 2024 Michael (gm.ywr.gorau@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]==============]

-- set to false for needing to copy text into regular buffer in order to open it
local clipPrimary=true

require "io"
require "os"

local function grab_output(cmd)
	local p = io.popen(cmd)
	if not p then
		return nil
	end
	local out = p:read("*all")
	local res, stat, code = p:close()
	if code ~= 0 then
		-- the text like "xclip: Error: There is no owner for the PRIMARY selection"
		-- is useless
		return nil
	end
	return out
end

local session = os.getenv("XDG_SESSION_TYPE")
local grab_cmd = ({
	wayland = clipPrimary
		and "wl-paste -p"
		or "wl-paste",
	x11 = clipPrimary
		and "xclip -o"
		or "xclip -o -selection clipboard"
})
[session]
if not grab_cmd then
	error("unknown session")
end
local clip = grab_output(grab_cmd)
if not clip then
	return
end

print("grab_cmd", grab_cmd)
print("clip", clip)

-- now we can exec this with kate or another editor
-- for example kate supports opening "/path/to/myfile.cpp:47", ideally fitting for compilers' output
local cl = #clip
if clip:sub(cl, cl) == '\n' then
	clip = clip:sub(1, cl - 1)
end
if not clip:find('\n') then
	os.execute("kate ".. clip)
	return
end

-- but the clipboard could contain more than that line? so parse this text and open more

local openfiles = {}
local begin = 1
while true do
	-- match "/path/to/myfile.cpp:47"
	local b, e = clip:find("/[/\\.0-9a-zA-Z]+:%d+", begin)
	if not b then
		break
	end
	-- try to match ending of "/path/to/myfile.cpp:47:98"
	local bb, ee = clip:find(":%d+", e + 1)
	if bb == e + 1 then
		e = ee
	end
	table.insert(openfiles, clip:sub(b, e))
	begin = e + 1
end

for i, v in ipairs(openfiles) do
	os.execute("kate ".. v)
end
