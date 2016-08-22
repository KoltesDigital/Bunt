require("src/entity")
require("src/bodyComponent.lua")
require("src/logicComponent.lua")
require("src/spriteComponent.lua")
require("src/spriteEngine.lua")

local weakKeys = {__mode = "k"}
local weakValues = {__mode = "v"}

Game = {}
Game.__index = Game

function Game.create(options)
	local self = options or {}
	setmetatable(self, Game)
	
	self.addCallback = function(a, b, c)
		--print("add", a, a and a.name, b, b and b.name)
		if a and not self.bodiesToDelete[a] and b and not self.bodiesToDelete[b] then
			a:trigger("addContact", b, c, false)
			b:trigger("addContact", a, c, true)
		end
	end
	self.persistCallback = function(a, b, c)
		--print("per", a and a.name, b and b.name)
	end
	self.removeCallback = function(a, b, c)
		--print("remove", a, a and a.name, b, b and b.name)
		if self.bodiesToDelete[a] then
			self.bodiesToDelete[a] = self.bodiesToDelete[a] - 1
			if self.bodiesToDelete[a] == 0 then
				a:destroy()
			end
			a = nil
		end
		
		if self.bodiesToDelete[b] then
			self.bodiesToDelete[b] = self.bodiesToDelete[b] - 1
			if self.bodiesToDelete[b] == 0 then
				b:destroy()
			end
			b = nil
		end
		
		if a and b then
			a:trigger("removeContact", b, c, false)
			b:trigger("removeContact", a, c, true)
		end
	end
	self.resultCallback = function()
	end
	
	self.entityNames = {}
	setmetatable(self.entityNames, weakValues)
	
	self.entityTypes = {}
	setmetatable(self.entityTypes, {__index = _G})
	
	local entitiesFunction = assert(love.filesystem.load(constants.dataPath .. "entities/entities.lua"))
	setfenv(entitiesFunction, self.entityTypes)
	entitiesFunction()
	
	love.graphics.setBackgroundColor(255, 255, 128)
	
	self.entities = {}
	self.bodiesToDelete = {}
	self.joints = {}
	
	self.buntImage = love.graphics.newImage(constants.dataPath .. "images/bunt.png")
	self.backgroundImage = love.graphics.newImage(constants.dataPath .. "images/background.png")
	self.signImage = love.graphics.newImage(constants.dataPath .. "images/sign.png")
	self.balloonImage = love.graphics.newImage(constants.dataPath .. "images/balloon.png")
	
	self.time = 0
	self.actions = {}
	
	self.gfxImages = {
		balloon = {
			image = love.graphics.newImage(constants.dataPath .. "images/gfxBalloon.png"),
			x = 32,
			y = 32
		},
		bump = {
			image = love.graphics.newImage(constants.dataPath .. "images/gfxBump.png"),
			x = 32,
			y = 32
		},
		cannon = {
			image = love.graphics.newImage(constants.dataPath .. "images/gfxCannon.png"),
			x = 32,
			y = 32
		},
		explosion = {
			image = love.graphics.newImage(constants.dataPath .. "images/explosion.png"),
			x = 64,
			y = 64
		},
		star = {
			image = love.graphics.newImage(constants.dataPath .. "images/gfxStar.png"),
			x = 32,
			y = 32
		}
	}
	
	self.sfxSources = {
		airBalloon = constants.dataPath .. "sounds/airBalloon.wav",
		balloon = constants.dataPath .. "sounds/balloon.wav",
		bump = constants.dataPath .. "sounds/bump.wav",
		cannonfire = constants.dataPath .. "sounds/cannonfire.wav",
		cannoninit = constants.dataPath .. "sounds/cannoninit.wav",
		car = constants.dataPath .. "sounds/car.wav",
		explosion = constants.dataPath .. "sounds/explosion.wav",
		firework = constants.dataPath .. "sounds/firework.wav",
		frog = constants.dataPath .. "sounds/frog.wav",
		star = constants.dataPath .. "sounds/jingle.wav"
	}
	
	self:loadMenu()
	
	return self
end

function Game:unload()
	for joint in pairs(self.joints) do
		joint:destroy()
	end
	self.joints = {}
	
	for entity in pairs(self.entities) do
		entity:removeFromScene()
	end
	self.entities = {}
	
	self.gfx = {}
	self.sfx = {}
	self.timeouts = {}
	
	self.puzzle = {}
	self.choice = nil
	self.actions = {}
end

function Game:loadMenu()
	self.state = "menu"
	self:unload()
end

function Game:loadLevel(filename)
	self.lastLevel = filename
	self.state = "game"
	self.subState = false

	self:unload()
	self.stars = 0
	
	local levelFunction = assert(love.filesystem.load(constants.dataPath .. "levels/" .. filename))
	setfenv(levelFunction, self.entityTypes)
	local level, joints
	self.info, level, joints = levelFunction()
	
	world = love.physics.newWorld(-100, -1000, 1380, 1000)
	world:setMeter(100)
	world:setGravity(0, 980)
	world:setCallbacks(self.addCallback, self.persistCallback, self.removeCallback, self.resultCallback)
	
	self.ground = Entity.create{
		x = 640,
		y = 748,
		static = true
	}
	self.ground.components.body = BodyComponent.create{
		shape = {
			type = "rectangle",
			x = 0,
			y = 0,
			width = 1380,
			height = 200
		}
	}
	
	self:addEntity(self.ground)
	
	for _, entity in pairs(level) do
		self:addEntity(entity)
	end
	
	for _, joint in pairs(joints) do
		local a = self.entityNames[joint.a]
		local b, bBody
		if joint.b then
			b = self.entityNames[joint.b]
			bBody = b.components.body.body
		else
			bBody = self.ground.components.body.body
		end
		if joint.type == "revolute" then
			local j = love.physics.newRevoluteJoint(a.components.body.body, bBody, joint.x, joint.y)
			self.entities[a][j] = true
			if b then
				self.entities[b][j] = true
			end
			self.joints[j] = true
		elseif joint.type == "distance" then
			local j = love.physics.newDistanceJoint(a.components.body.body, bBody, joint.x1, joint.y1, joint.x2, joint.y2)
			self.entities[a][j] = true
			if b then
				self.entities[b][j] = true
			end
			self.joints[j] = true
		end
	end
end

function Game:reloadLevel()
	self:loadLevel(self.lastLevel)
end

function Game:addEntity(entity)
	local t = {}
	setmetatable(t, weakKeys)
	self.entities[entity] = t
	
	if entity.name then
		self.entityNames[entity.name] = entity
	end
	
	entity:addToScene()
end

function Game:removeEntity(entity)
	if self.entities[entity] then
		for joint in pairs(self.entities[entity]) do
			self.joints[joint] = nil
			joint:destroy()
		end
		entity:removeFromScene()
		self.entities[entity] = nil
	end
end

function Game:getEntity(name)
	return self.entityNames[name]
end

function Game:setTimeout(fn, time)
	self.timeouts[{
		fn = fn,
		time = self.time + time
	}] = true
end

function Game:trigger(event, ...)
	for entity in pairs(self.entities) do
		entity:trigger(event, ...)
	end
end

function Game:action(color, enabled)
	if not self.actions[color] and enabled then
		for entity in pairs(self.entities) do
			if entity.color == color then
				entity:trigger("startAction")
			end
		end
		self.actions[color] = true
	elseif self.actions[color] and not enabled then
		for entity in pairs(self.entities) do
			if entity.color == color then
				entity:trigger("stopAction")
			end
		end
		self.actions[color] = false
	end
end

function Game:keyPressed(key, unicode)
	if key == "escape" then
		love.event.push("q")
	end
end

function Game:keyReleased(key, unicode)
end

function Game:addGFX(name, x, y, angle)
	local t = {
		name = name,
		time = self.time,
		x = x,
		y = y,
		angle = angle
	}
	self.gfx[t] = true
end

function Game:addSFX(name)
	local source = love.audio.newSource(self.sfxSources[name])
	source:play()
	self.sfx[source] = true
end

function Game:transition(fn)
	self.transitionTime = self.time + constants.fadeTime
	self.transitionFunction = fn
end

function Game:update(dt)
	if dt > 0.2 then
		return
	end

	self.time = self.time + dt
	if self.transitionTime and self.time >= self.transitionTime then
		self.transitionFunction()
		self.time = 0
		self.transitionTime = false
	end

	self:action("blue", love.keyboard.isDown("1") or love.keyboard.isDown("f1") or love.joystick.isDown(0, 2))
	self:action("green", love.keyboard.isDown("2") or love.keyboard.isDown("f2") or love.joystick.isDown(0, 0))
	self:action("yellow", love.keyboard.isDown("3") or love.keyboard.isDown("f3") or love.joystick.isDown(0, 3))
	self:action("red", love.keyboard.isDown("4") or love.keyboard.isDown("f4") or love.joystick.isDown(0, 1))
	self:action("white", love.keyboard.isDown("5") or love.keyboard.isDown("f5") or love.joystick.isDown(0, 4) or love.joystick.isDown(0, 5) or love.joystick.isDown(0, 6) or love.joystick.isDown(0, 7))
	
	if self.state == "game" then
		if self.actions.white then
			self.igTime = self.time
			self.state = "igmenu"
		end
		
		self:trigger("beforePhysics", dt)
		world:update(dt)
		self:trigger("afterPhysics", dt)
		
		if self.stars == 0 and not self.transitionTime then
			self:transition(function()
				if self.info.next then
					self:loadLevel(self.info.next)
				else
					self.state = "end"
					self:unload()
				end
			end)
		end
		
	elseif self.state == "menu" and not self.transitionTime then
		local start = function()
			self:loadLevel("crate.lua")
		end
		
		if self.actions.blue then
			self.choice = 1
			self:addGFX("balloon", 250 + 32, 200 + 32, 0)
			self:addSFX("balloon")
			self:transition(start)
		end
		
		if self.actions.green then
			self.choice = 2
			self:addGFX("balloon", 450 + 32, 450 + 32, 0)
			self:addSFX("balloon")
			self:transition(start)
		end
		
		if self.actions.yellow then
			self.choice = 3
			self:addGFX("balloon", 800 + 32, 350 + 32, 0)
			self:addSFX("balloon")
			self:transition(start)
		end
		
		if self.actions.red then
			self.choice = 4
			self:addGFX("balloon", 1080 + 32, 550 + 32, 0)
			self:addSFX("balloon")
			self:transition(start)
		end
		
		if self.transitionTime then
			self.transitionTime = self.transitionTime + 1
		end
		
	elseif self.state == "igmenu" then
		if not self.actions.white and not self.transitionTime then
			self:transition(function()
				self:reloadLevel()
			end)
		end
		
		if self.time - self.igTime > 2 and not self.transitionTime then
			self:transition(function()
				self:loadMenu()
			end)
		end
		
	elseif self.state == "end" and self.time >= 4 and not self.transitionTime then
		self:transition(function()
			self:loadMenu()
		end)
	end
	
	for gfx in pairs(self.gfx) do
		if self.time - gfx.time > constants.gfxTime then
			self.gfx[gfx] = nil
		end
	end
	
	for source in pairs(self.sfx) do
		if source:isStopped() then
			self.sfx[source] = nil
		end
	end
	
	for timeout in pairs(self.timeouts) do
		if timeout.time <= self.time then
			timeout.fn()
			self.timeouts[timeout] = nil
		end
	end
end

function Game:render()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(self.backgroundImage, 0, 0)
	
	love.graphics.setColor(0, 0, self.actions.blue and 128 or 255)
	love.graphics.draw(self.signImage, 140, 710)
	
	love.graphics.setColor(0, self.actions.green and 128 or 255, 0)
	love.graphics.draw(self.signImage, 340, 710)
	
	love.graphics.setColor(self.actions.yellow and 128 or 255, self.actions.yellow and 128 or 255, 0)
	love.graphics.draw(self.signImage, 540, 710)
	
	love.graphics.setColor(self.actions.red and 128 or 255, 0, 0)
	love.graphics.draw(self.signImage, 740, 710)
	
	love.graphics.setColor(self.actions.white and 128 or 255, self.actions.white and 128 or 255, self.actions.white and 128 or 255)
	love.graphics.draw(self.signImage, 1022, 710)
	
	love.graphics.setColor(255, 255, 255)
	love.graphics.print("1", 196, 722)
	love.graphics.print("2", 396, 722)
	love.graphics.print("3", 596, 722)
	love.graphics.print("4", 796, 722)
	love.graphics.print("5", 1076, 722)
	
	if self.state == "game" then
		spriteEngine:render()
		
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("Restart", 1010, 670)
	elseif self.state == "menu" then
		if self.choice ~= 1 then
			love.graphics.setColor(0, 0, 255)
			love.graphics.draw(self.balloonImage, 250, 200)
		end
		
		if self.choice ~= 2 then
			love.graphics.setColor(0, 255, 0)
			love.graphics.draw(self.balloonImage, 450, 450)
		end
		
		if self.choice ~= 3 then
			love.graphics.setColor(255, 255, 0)
			love.graphics.draw(self.balloonImage, 800, 350)
		end
		
		if self.choice ~= 4 then
			love.graphics.setColor(255, 0, 0)
			love.graphics.draw(self.balloonImage, 1080, 550)
		end
		
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.buntImage, 512, 100)
		
		love.graphics.print("Bloutiouf 2012", 10, 10)
		love.graphics.setFont(creditsFont)
		love.graphics.print("http://bloutiouf.blogspot.com/", 10, 50)
		love.graphics.printf("Sounds: cfork, Cyberkineticfilms, Erdie, esformouse,", 10, 10, 1260, "right")
		love.graphics.printf("junggle, kantouth, northern87, sandyrb", 10, 34, 1260, "right")
		love.graphics.printf("Font: Nayda Florez", 10, 64, 1260, "right")
		love.graphics.setFont(font)
		love.graphics.print("Press a key from 1 to 4 to start the game", 100, 660)
		
	elseif self.state == "igmenu" then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.buntImage, 512, 100)
		love.graphics.print("Release the key to restart the level", 280, 300)
		love.graphics.print("Keep the key pressed to quit", 360, 400)
	
	elseif self.state == "end" then
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("You did it!", 530, 150)
		love.graphics.print("Thanks for playing!", 440, 220)
	end
	
	for gfx in pairs(self.gfx) do
		local ratio = (self.time - gfx.time) / constants.gfxTime
		local image = self.gfxImages[gfx.name]
		love.graphics.setColor(255, 255, 255, (1 - ratio) * 255)
		love.graphics.draw(image.image, gfx.x, gfx.y, gfx.angle, 1 + ratio * constants.scaleFactor, 1 + ratio * constants.scaleFactor, image.x, image.y)
	end
	
	local fade = 255
	fade = math.min(fade, self.time / constants.fadeTime * 255)
	if self.transitionTime then
		fade = math.min(fade, (self.transitionTime - self.time) / constants.fadeTime * 255)
	end
	if fade < 255 then
		love.graphics.setColor(0, 0, 0, 255 - fade)
		love.graphics.rectangle("fill", 0, 0, 1280, 800)
	end
end
