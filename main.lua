require("constants")
require("src/game")

function love.load()
	font = love.graphics.newFont(constants.dataPath .. "fonts/Oohlalalulucurvy.ttf", 40)
	creditsFont = love.graphics.newFont(constants.dataPath .. "fonts/Oohlalalulucurvy.ttf", 24)
	love.graphics.setFont(font)
	
	love.mouse.setVisible(false)
	
	game = Game.create()
	
	--game:loadLevel("crate2.lua")
end

function love.keypressed(key, unicode)
	game:keyPressed(key, unicode)
end

function love.keyreleased(key, unicode)
	game:keyReleased(key, unicode)
end

function love.update(dt)
	game:update(dt)
end

function love.draw()
	game:render()
end
