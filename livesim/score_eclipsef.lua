-- Score eclipse flash animation
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

local tween = require("tween")
local love = require("love")
local DEPLS, AquaShine = ...
local ScoreEclipseF = {}

local eclipse_data = {scale = 1, opacity = 1}
local eclipse_tween = tween.new(500, eclipse_data, {scale = 1.6, opacity = 0}, "outSine")

local bar_data = {opacity = 1}
bar_data.tween = tween.new(300, bar_data, {opacity = 0})
eclipse_tween:update(500)
bar_data.tween:update(300)

local function init()
	-- Load score eclipse related image
	ScoreEclipseF.Img = AquaShine.LoadImage("assets/image/live/l_etc_46.png")
	ScoreEclipseF.Img2 = AquaShine.LoadImage("assets/image/live/l_gauge_17.png")

	return ScoreEclipseF
end

function ScoreEclipseF.Update(deltaT)
	if ScoreEclipseF.Replay then
		eclipse_tween:reset()
		bar_data.tween:reset()
		ScoreEclipseF.Replay = false
	end

	ScoreEclipseF.BarDataStats = not(bar_data.tween:update(deltaT))
	ScoreEclipseF.EclipseStats = not(eclipse_tween:update(deltaT))
end

function ScoreEclipseF.Draw()
	if ScoreEclipseF.BarDataStats then
		love.graphics.setColor(1, 1, 1, eclipse_data.opacity * DEPLS.LiveOpacity)
		love.graphics.draw(ScoreEclipseF.Img, 484, 72, 0, eclipse_data.scale, eclipse_data.scale, 159, 34)
	end

	if ScoreEclipseF.EclipseStats and ScoreEclipseF.ScoreBar.BarTapFlash then
		love.graphics.setColor(1, 1, 1, bar_data.opacity * DEPLS.LiveOpacity)
		love.graphics.draw(ScoreEclipseF.Img2, 5, 8)
	end
end

return init()
