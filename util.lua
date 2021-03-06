-- Utilities helper function
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

local love = require("love")
local Luaoop = require("libs.Luaoop")
require("libs.ls2x")
local color = require("color")
local hasLVEP = not(not(package.preload.lvep))
local lvep
if hasLVEP then
	lvep = require("lvep")
end

local version11 = love._version >= "11.0"
local util = {}

function util.basename(file)
	if not(file) then return end
	local x = file:reverse()
	return x:sub(1, (x:find("/") or x:find("\\") or #x + 1) - 1):reverse()
end

function util.fileExists(path)
	if version11 then
		return not(not(love.filesystem.getInfo(path, "file")))
	else
		return love.filesystem.isFile(path)
	end
end

function util.directoryExist(path)
	if version11 then
		return not(not(love.filesystem.getInfo(path, "directory")))
	else
		return love.filesystem.isDirectory(path)
	end
end

function util.removeExtension(file)
	return file:sub(1, -(file:reverse():find(".", 1, true) or 0) - 1)
end

function util.getExtension(file)
	local pos = file:reverse():find(".", 1, true)
	if not(pos) then return ""
	else return file:sub(-pos + 1) end
end

-- ext nust contain dot
function util.substituteExtension(file, ext, hasext)
	if hasext then
		if util.fileExists(file) then
			return file
		else
			file = util.removeExtension(file)
		end
	end

	for _, v in ipairs(ext) do
		local a = file..v
		if util.fileExists(a) then
			return a
		end
	end

	return nil
end

local supportedAudioExtensions = {".wav", ".ogg", ".mp3"} -- in order
function util.getNativeAudioExtensions()
	return supportedAudioExtensions
end

function util.clamp(value, min, max)
	return math.max(math.min(value, max), min)
end

function util.isCursorSupported()
	if version11 then
		return love.mouse.isCursorSupported()
	else
		return love.mouse.hasCursor()
	end
end

function util.releaseObject(obj)
	if version11 then return obj:release() end
end

function util.getChannelCount(sounddata)
	if version11 then return sounddata:getChannelCount()
	else return sounddata:getChannels() end
end

-- Class for wrapping Lua io file to LOVE file compatible
local fileWrapClass = Luaoop.class("util.FileWrapper")

function fileWrapClass:__construct(path, file)
	self.file = file
	self.path = path
end

function fileWrapClass:__destruct()
	if self.file then self.file:close() end
end

function fileWrapClass:read(n)
	return self.file:read(tonumber(n) or "*a")
end

function fileWrapClass:write(str, size)
	if type(str) == "userdata" and str:typeOf("Data") then
		str = str:getString()
	end

	return self.file:write(tostring(str):sub(1, size))
end

function fileWrapClass:seek(offset)
	return self.file:seek("set", offset)
end

function fileWrapClass:tell()
	return self.file:seek("cur")
end

function fileWrapClass:close()
	self.file:close()
	self.file = nil
end

function fileWrapClass:getFilename()
	return self.path
end

function util.newFileWrapper(path, mode)
	local file, msg = io.open(path, mode)
	if not(file) then return nil, msg end
	return fileWrapClass(path, file)
end

function util.addTextWithShadow(text, str, x, y, intensity)
	x = x or 0 y = y or 0
	intensity = intensity or 1
	text:add({color.black, str}, x-intensity, y-intensity)
	text:add({color.black, str}, x+intensity, y+intensity)
	text:add({color.white, str}, x, y)
end

function util.lerp(a, b, t)
	return a * (1 - t) + b * t
end

function util.distance(x1, y1, x2, y2, squared)
	local value = (x2-x1)^2+(y2-y1)^2
	if squared then
		return value
	else
		return math.sqrt(value)
	end
end

function util.sign(n)
	return n > 0 and 1 or (n < 0 and -1 or 0)
end

function util.round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	local x = num * mult
	if util.sign(x) >= 0 then
		return math.floor(x + 0.5) / mult
	else
		return math.ceil(x - 0.5) / mult
	end
end

function util.deepCopy(orig)
	if type(orig) == 'table' then
		local copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[orig_key] = util.deepCopy(orig_value)
		end
		return copy
	else -- number, string, boolean, etc
		return orig
	end
end

function util.isValueInArray(array, value)
	for i = 1, #array do
		if array[i] == value then
			return i
		end
	end

	return nil
end

function util.isMobile()
	return love._os == "iOS" or love._os == "Android"
end

function util.compareLOVEVersion(maj, min, rev)
	if love._version_major > maj then
		return 1
	elseif love._version_major < maj then
		return -1
	elseif min then
		if love._version_minor > min then
			return 1
		elseif love._version_minor < min then
			return -1
		elseif rev then
			if love._version_revision > rev then
				return 1
			elseif love._version_revision < rev then
				return -1
			end
		end
	end
	-- equal
	return 0
end

function util.newDecoder(path)
	if hasLVEP then
		local s, v = pcall(love.sound.newDecoder, path)
		if not(s) then
			return lvep.newDecoder(path)
		else
			return v
		end
	else
		return love.sound.newDecoder(path)
	end
end

function util.newVideoStream(path)
	if hasLVEP then
		local s, v = pcall(love.video.newStream, path)
		if not(s) then
			return lvep.newVideoStream(path)
		else
			return v
		end
	else
		return love.video.newVideoStream(path)
	end
end

return util
