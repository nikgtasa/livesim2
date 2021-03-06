-- Very legacy DEPLS project beatmap loader
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

local Luaoop = require("libs.Luaoop")
local log = require("logging")
local love = require("love")
local util = require("util")
local baseLoader = require("game.beatmap.base")
local beatmap = require("beatmap")

-------------------------
-- DEPLS Beatmap Class --
-------------------------

local deplsLoader = Luaoop.class("beatmap.DEPLS", baseLoader)

function deplsLoader:__construct(path)
	local internal = Luaoop.class.data(self)
	internal.path = path

	-- get list of files named "beatmap"
	local possibleBeatmapCandidate = {}
	for _, file in ipairs(love.filesystem.getDirectoryItems(path)) do
		if util.removeExtension(file) == "beatmap" then
			possibleBeatmapCandidate[#possibleBeatmapCandidate + 1] = path..file
		end
	end

	if #possibleBeatmapCandidate == 0 then
		error("cannot find beatmap file candidate")
	end

	-- make sure beatmap.json has highest priority, then ls2
	for i = 1, #possibleBeatmapCandidate do
		if util.getExtension(possibleBeatmapCandidate[i]):lower() == "ls2" then
			table.insert(possibleBeatmapCandidate, 1, table.remove(possibleBeatmapCandidate, i))
			break
		end
	end
	for i = 1, #possibleBeatmapCandidate do
		if util.getExtension(possibleBeatmapCandidate[i]):lower() == "json" then
			table.insert(possibleBeatmapCandidate, 1, table.remove(possibleBeatmapCandidate, i))
			break
		end
	end

	-- test all file candidates
	for i = 1, #possibleBeatmapCandidate do
		local file = love.filesystem.newFile(possibleBeatmapCandidate[i], "r")
		if file then
			for j = 1, #beatmap.fileLoader do
				file:seek(0)
				local s, v = pcall(beatmap.fileLoader[j], file)

				if s then
					assert(Luaoop.class.is(v, baseLoader), "invalid beatmap object returned")
					internal.beatmap = v
					return
				end
			end
		end
	end

	error("cannot find beatmap file candidate")
end

function deplsLoader:getFormatName()
	local internal = Luaoop.class.data(self)
	local s1, s2 = internal.beatmap:getFormatName()
	return "DEPLS: "..s1, "depls_"..s2
end

function deplsLoader:getHash()
	local internal = Luaoop.class.data(self)
	return md5(internal.beatmap:getHash()..self:getFormatName())
end

function deplsLoader:getNotesList()
	local internal = Luaoop.class.data(self)
	return internal.beatmap:getNotesList()
end

function deplsLoader:getName()
	local internal = Luaoop.class.data(self)
	local name = internal.beatmap:getName()

	if not(name) then
		local coverArt = self:getCoverArt()
		if coverArt then
			name = coverArt.title
		end
	end

	return name
end

local customUnitPossibleExt = {".png", ".tga", ".txt"}
function deplsLoader:getCustomUnitInformation()
	local internal = Luaoop.class.data(self)
	local beatmapUnitInfo = internal.beatmap:getCustomUnitInformation()
	local imageCache = {}
	local res = {}

	for i = 1, 9 do
		if beatmapUnitInfo[i] then
			res[i] = beatmapUnitInfo[i]
		else
			local filename = util.substituteExtension(internal.path.."unit_pos_"..i, customUnitPossibleExt)

			if filename then
				if util.getExtension(filename) == "txt" then
					local imageFile = love.filesystem.read(filename)

					if not(imageCache[imageFile]) then
						local s, v = pcall(love.image.newImageData, internal.path..imageFile)
						if s then
							imageCache[imageFile] = v
						end
					end

					if imageCache[imageFile] then
						res[i] = imageCache[imageFile]
					end
				else
					if not(imageCache[filename]) then
						local s, v = pcall(love.image.newImageData, filename)
						if s then
							imageCache[filename] = v
						end
					end

					if imageCache[filename] then
						res[i] = imageCache[filename]
					end
				end
			end
		end
	end

	return res
end

local coverArtExtensions = {".png", ".jpg", ".jpeg", ".tga", ".bmp"}
function deplsLoader:getCoverArt()
	local internal = Luaoop.class.data(self)
	local coverInfo = internal.beatmap:getCoverArt()

	if coverInfo then
		return coverInfo
	else
		local coverName = internal.path.."cover.txt"
		local coverImage = util.substituteExtension(internal.path.."cover", coverArtExtensions)

		if util.fileExists(coverName) and coverImage then
			local cover = {}
			local lineIter = love.filesystem.lines(coverName)

			cover.title = lineIter()
			cover.info = lineIter()
			cover.image = love.image.newImageData(coverImage)

			return cover
		end
	end
end

function deplsLoader:getAudioPathList()
	local internal = Luaoop.class.data(self)
	return {internal.path.."songFile"}
end

function deplsLoader:getAudio()
	local internal = Luaoop.class.data(self)
	local beatmapAudio = internal.beatmap:getAudio()

	if beatmapAudio then
		return beatmapAudio
	else
		return baseLoader.getAudio(self)
	end
end

local videoExtension = {".ogg", ".ogv"}
function deplsLoader:getBackground(video)
	local internal = Luaoop.class.data(self)
	local bg = internal.beatmap:getBackground() -- file loader can't load video
	local videoObj

	if video then
		local f = util.substituteExtension(internal.path.."video_background", videoExtension)
		if f then
			videoObj = util.newVideoStream(f)
		end
	end

	if bg == nil or bg == 0 then
		local bgfile = util.substituteExtension(internal.path.."background", coverArtExtensions)
		if bgfile then
			local mode = {1}
			local backgrounds = {}
			mode[#mode + 1] = love.image.newImageData(bgfile)

			for i = 1, 4 do
				bgfile = util.substituteExtension(internal.path.."background-"..i, coverArtExtensions)
				if bgfile then
					backgrounds[i] = love.image.newImageData(bgfile)
				end
			end

			if backgrounds[1] and backgrounds[2] then
				mode[1] = mode[1] + 2
				mode[#mode + 1] = backgrounds[1]
				mode[#mode + 1] = backgrounds[2]
			elseif not(backgrounds[1]) ~= not(backgrounds[2]) then
				log.warning("noteloader.depls", "missing left or right background. Discard both!")
			end
			if backgrounds[3] and backgrounds[4] then
				mode[1] = mode[1] + 4
				mode[#mode + 1] = backgrounds[3]
				mode[#mode + 1] = backgrounds[4]
			elseif not(backgrounds[3]) ~= not(backgrounds[4]) then
				log.warning("noteloader.depls", "missing top or bottom background. Discard both!")
			end

			if videoObj then
				mode[1] = mode[1] + 8
				mode[#mode + 1] = videoObj
			end

			return mode
		elseif util.fileExists(internal.path.."background.txt") then
			-- love.filesystem.read returns 2 values, and it can be problem
			-- for background ID 10 and 11, so pass "nil" as 2nd argument of tonumber
			local n = tonumber(love.filesystem.read(internal.path.."background.txt"), nil)
			if videoObj then
				return {8, n, videoObj}
			else
				return n
			end
		end
	elseif videoObj then
		return {8, bg, videoObj}
	else
		return bg
	end

	if videoObj then
		return {8, 0, videoObj}
	else
		return 0
	end
end

function deplsLoader:getStoryboardData()
	local internal = Luaoop.class.data(self)
	local embeddedStory = internal.beatmap:getStoryboardData()

	if embeddedStory then
		embeddedStory.path = internal.path
		return embeddedStory
	end
	local file = util.substituteExtension(internal.path.."storyboard", {".yaml", ".yml"}, false)

	if file then
		return {
			type = "yaml",
			storyboard = love.filesystem.read(file):gsub("\r\n", "\n"),
			path = internal.path
		}
	end

	file = internal.path.."storyboard.lua"
	if util.fileExists(file) then
		local script = love.filesystem.read(file)
		-- Do not load bytecode
		if script:find("\27", 1, true) == nil and loadstring(script) then
			return {
				type = "lua",
				storyboard = script,
				path = internal.path
			}
		end
	end

	return nil
end

function deplsLoader:getLiveClearVoice()
	local internal = Luaoop.class.data(self)
	local audio = internal.beatmap:getLiveClearVoice()

	if not(audio) then
		local file = util.substituteExtension(internal.path.."live_clear", util.getNativeAudioExtensions())
		if file then
			local s, msg = pcall(util.newDecoder, file)
			if s then
				audio = msg
			else
				log.errorf("noteloader.depls", "live clear sound not supported: %s", msg)
			end
		end
	end

	return audio
end

return deplsLoader, "folder"
