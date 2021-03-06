-- Splash screen
-- Part of Live Simulator: 2
-- See copyright notice in main.lua
-- luacheck: read_globals DEPLS_VERSION DEPLS_VERSION_NUMBER

local love = require("love")
local timer = require("libs.hump.timer")

local color = require("color")
local mainFont = require("font")
local gamestate = require("gamestate")
local loadingInstance = require("loading_instance")

local splash = gamestate.create {
	fonts = {
		version = {24}
	},
	images = {
		icon = {"icon1024:assets/image/icon/icon_1024x1024.png", {mipmaps = true}}
	},
	audios = {},
}

local function done()
	gamestate.replace(loadingInstance.getInstance(), "mainMenu")
end

local function skip(self)
	local persist = self.persist

	if not(persist.setShader) then
		self.data.timer:clear()
		persist.setShader = true
		-- Skip
		self.data.timer:tween(0.5, persist, {eraser = -1})
		self.data.timer:after(0.5, done)
	end
end

function splash:load()
	if not(self.data.title) then
		local title = love.graphics.newText(mainFont.get(72))
		title:add({color.black50PT, "Live Simulator: 2"}, 2, 2)
		title:add({color.black50PT, "Live Simulator: 2"}, -2, -2)
		title:add({color.white, "Live Simulator: 2"}, 0, 0)
		self.data.title = title
	end
	if not(self.data.version) then
		self.data.version = love.graphics.newText(
			self.assets.fonts.version,
			string.format("v%s (%08d)\nPowered by LÖVE Framework (LÖVE %s)",
				DEPLS_VERSION, DEPLS_VERSION_NUMBER, love._version
			)
		)
	end
	if not(self.data.shader) then
		self.data.shader = love.graphics.newShader([[
		extern number opacity;

		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 fc)
		{
			vec4 x = Texel(tex, tc);
			return vec4(x.rgb, x.a * (tc.x >= opacity ? 0.0 : 1.0)) * color;
		}
		]])
	end
	if not(self.data.timer) then
		self.data.timer = timer.new()
	end
end

function splash:start()
	local persist = self.persist
	persist.iconOpacity = 0
	persist.iconPosX = 480
	persist.iconRot = 2*math.pi + 0.60317
	persist.textOpacity = 0
	persist.eraser = 1
	persist.skipped = false
	persist.done = false
	persist.setShader = false

	-- Responsible for the splash
	self.data.timer:script(function(wait)
		wait(0.1)

		-- Show icon in 250ms at +480+320 start at 0ms. linear
		self.data.timer:tween(0.25, persist, {iconOpacity = 1})
		wait(0.25)

		-- Rotate icon in 500ms and move to left at +166+320 start at 750ms. inOutCubic
		self.data.timer:tween(0.5, persist, {iconRot = 0, iconPosX = 166}, "in-out-cubic")
		wait(0.5)

		-- Fade "Live Simulator: 2" string in 500ms at +285+284. linear
		self.data.timer:tween(0.5, persist, {textOpacity = 1})
		-- Delay 250ms.
		wait(0.5+0.25)

		-- Erase the icon and text in 500ms with shader. linear
		persist.setShader = true
		self.data.timer:tween(0.5, persist, {eraser = -1})
		wait(0.5)

		persist.done = true
		self.data.timer:clear()
		return done()
	end)
end

function splash:update(dt)
	self.data.shader:send("opacity", math.max(self.persist.eraser, 0))
	return self.data.timer:update(dt * 0.7)
end

function splash:draw()
	local persist = self.persist

	love.graphics.clear(color.hex00BBFF)
	if persist.done then return end

	if persist.setShader then
		love.graphics.setShader(self.data.shader)
	end

	-- Draw icon
	love.graphics.setColor(color.get(255, 255, 255, persist.iconOpacity))
	love.graphics.draw(self.assets.images.icon, persist.iconPosX, 320, persist.iconRot, 128/1024, 128/1024, 512, 512)
	love.graphics.draw(self.data.version, 5, 600, 0, 2/3, 2/3)
	-- Draw text
	love.graphics.setColor(color.get(255, 255, 255, persist.textOpacity))
	love.graphics.draw(self.data.title, 285, 284)
	-- Clear shader
	love.graphics.setShader()
end

splash:registerEvent("keyreleased", skip)
splash:registerEvent("mousereleased", skip)

return splash
