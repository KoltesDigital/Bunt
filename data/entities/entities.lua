function airBalloon(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "airBalloon.png",
		x = 64,
		y = 128,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		fixedRotation = true,
		shape = {
			type = "polygon",
			points = {
				18, -110,
				55, -73,
				55, -26,
				25, 116,
				-25, 116,
				-55, -26,
				-55, -73,
				-18, -110
			}
		},
		beforePhysics = function(component, dt)
			if self.inAction then
				component.body:applyForce(0, -25)
			end
		end
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function(component)
			self.inAction = true
			game:addSFX("airBalloon")
		end,
		stopAction = function(component)
			self.inAction = false
		end
	}
	
	return self
end

function balloon(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "balloon.png",
		x = 32,
		y = 32,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		--fixedRotation = true,
		shape = {
			type = "circle",
			x = 0,
			y = 0,
			radius = 28
		},
		beforePhysics = function(component, dt)
			component.body:applyForce(0, -5)
		end
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function(component)
			game:removeEntity(self)
			game:addGFX("balloon", self.x, self.y, self.angle)
			game:addSFX("balloon")
			game:trigger("explodedNearby", self, 10)
		end
	}
	
	return self
end

function bomb(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "bomb.png",
		x = 32,
		y = 32,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		shape = {
			type = "circle",
			x = 0,
			y = 0,
			radius = 16
		}
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function(component)
			game:removeEntity(self)
			game:addGFX("explosion", self.x, self.y, math.random(math.pi * 2))
			game:addSFX("explosion")
			game:trigger("explodedNearby", self, 200000)
		end
	}
	
	return self
end

function bump(options)
	local self = Entity.create(options)
	
	self.static = true
	
	if not self.angle then
		self.angle = 0
	end
	
	local shapeOff = {
		type = "rectangle",
		x = -20,
		y = 0, 
		width = 24,
		height = 42
	}
	
	local shapeOn = {
		type = "rectangle",
		x = -32,
		y = 0, 
		width = 128,
		height = 42
	}
	
	self.components.sprite = SpriteComponent.create{
		file = "bumpOff.png",
		x = 32,
		y = 32,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		bullet = true,
		shape = shapeOff
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function(component)
			self.action = true
			self.actionTime = game.time
			self:trigger("setShape", shapeOn)
			self:trigger("setSprite", "bumpOn.png")
			game:addGFX("bump", self.x, self.y, self.reverse and (math.pi + self.angle) or self.angle)
			game:addSFX("bump")
		end,
		stopAction = function(component)
			self.action = false
			self:trigger("setShape", shapeOff)
			self:trigger("setSprite", "bumpOff.png")
		end,
		addContact = function(component, entity, contact, reverse)
			if self.actionTime == game.time then
				local power = 2 * (self.reverse and -1 or 1)
				entity:trigger("applyImpulse", power * math.cos(self.angle), power * math.sin(self.angle))
				
			end
		end
	}
	
	return self
end

function cannon(options)
	local self = Entity.create(options)
	
	self.static = true
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "cannon.png",
		x = 32,
		y = 32,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		shape = {
			type = "polygon",
			points = {
				30, -1,
				30, 9,
				19, 15,
				-24, 15,
				-31, 9,
				-31, -3,
				-21, -16,
				4, -16
			}
		},
		beforePhysics = function(component, dt)
			if self.inContact and self.inAction and math.abs(self.angle) < 0.5 then
				component.body:applyForce(self.reverse and -4 or 4, 0)
			end
		end
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function(component)
			self.startTime = game.time
			game:addGFX("cannon", self.x, self.y, self.reverse and (math.pi + self.angle) or self.angle)
			game:addSFX("cannoninit")
		end,
		stopAction = function(component)
			local angle = self.reverse and (math.pi + self.angle) or self.angle
			local ball = cannonball{
				x = self.x + 49 * math.cos(angle),
				y = self.y + 49 * math.sin(angle),
				angle = angle,
				speed = math.min((game.time - self.startTime) * 1000, 3000)
			}
			game:addEntity(ball)
			game:addSFX("cannonfire")
		end
	}
	
	return self
end

function cannonball(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "cannonball.png",
		x = 16,
		y = 16,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		bullet = true,
		shape = {
			type = "circle",
			x = 0,
			y = 0,
			radius = 16
		},
		speed = self.speed
	}
	
	return self
end

function car(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "car.png",
		x = 32,
		y = 32,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		mass = 0.5,
		shape = {
			type = "polygon",
			points = {
				30, -1,
				30, 9,
				19, 15,
				--2, 10,
				-24, 15,
				-31, 9,
				-31, -3,
				-21, -16,
				4, -16
			}
		},
		beforePhysics = function(component, dt)
			if self.inContact and self.inAction and math.abs(self.angle) < 0.5 then
				component.body:applyForce(self.reverse and -12 or 12, 0)
			end
		end
	}
	
	local contacts = 0
	
	self.components.logic = LogicComponent.create{
		addContact = function(component, entity, contact, reverse)
			self.inContact = true
			contacts = contacts + 1
		end,
		removeContact = function(component, entity, contact, reverse)
			contacts = contacts - 1
			if contacts == 0 then
				self.inContact = false
			end
		end,
		startAction = function(component)
			self.inAction = true
			game:addSFX("car")
		end,
		stopAction = function(component)
			self.inAction = false
		end
	}
	
	return self
end

function crate(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "crate.png",
		x = 32,
		y = 32,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		shape = {
			type = "rectangle",
			x = 0,
			y = 0,
			width = 64,
			height = 64
		},
		afterPhysics = function(component, dt)
			component:updatePosition()
		end
	}
	
	return self
end

function firework(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	local launchTime
	
	self.components.sprite = SpriteComponent.create{
		file = "groundedFirework.png",
		x = 32,
		y = 32,
		layer = 3
	}
	
	self.components.body = BodyComponent.create{
		fixedRotation = true,
		shape = {
			type = "polygon",
			points = {
				0, -27, 
				6, -14,
				6, 32,
				-6, 32,
				-6, -14
			}
		},
		beforePhysics = function(component, dt)
			if self.state == "launched" then
				component.body:applyForce(0, -1)
			end
		end
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function()
			if not self.state then
				self.state = "launched"
				launchTime = game.time
				self.components.body.body:setPosition(self.components.body.body:getX(), self.components.body.body:getY() - 1)
				self:trigger("setSprite", "firework.png")
				self:trigger("setShape", {
					type = "polygon",
					points = {
						0, -27, 
						6, -14,
						6, 20,
						-6, 20,
						-6, -14
					}
				})
				game:addSFX("firework")
				game:trigger("fireworkLaunched", self.x)
			end
		end,
		addContact = function(component, entity, contact)
			if self.state == "launched" and game.time - launchTime > 0.2 then
				game:removeEntity(self)
				game:addGFX("explosion", self.x, self.y, self.angle)
				game:addSFX("explosion")
				game:trigger("explodedNearby", self, 10)
			end
		end
	}
	
	return self
end

function frog(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.state = "down"
	self.contacts = 0
	
	local targetX = self.x
	
	self.components.sprite = SpriteComponent.create{
		file = "frogDown.png",
		x = 64,
		y = 64,
		layer = 3
	}
	
	local groundTime
	local impulse = -10
	
	self.components.body = BodyComponent.create{
		fixedRotation = true,
		shape = {
			type = "rectangle",
			x = 0,
			y = 0,
			width = 128,
			height = 128
		},
		beforePhysics = function(component, dt)
			local x, y = component.body:getLinearVelocity()
			if y > 0 and self.state == "up" then
				self.state = "down"
				self.components.sprite:setSprite("frogDown.png")
			end
			component.body:setX(targetX)
		end
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function(component)
			if self.state == "idle" then
				self.state = "up"
				self.components.sprite:setSprite("frogUp.png")
				game:addSFX("frog")
				
				if game.time - groundTime < 0.2 then
					impulse = impulse - 1
				else
					impulse = -10
				end
				groundTime = false
				self.components.body.body:setLinearVelocity(0, 0)
				self.components.body.body:applyImpulse(0, impulse)
			end
		end,
		addContact = function()
			self.contacts = self.contacts + 1
			if self.state == "down" then
				if not groundTime then
					groundTime = game.time
				end
				self.state = "idle"
				self.components.sprite:setSprite("frog.png")
			end
		end,
		removeContact = function()
			self.contacts = self.contacts - 1
		end
	}
	
	return self
end

function plank(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "plank.png",
		x = 512,
		y = 2,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		bullet = true,
		mass = 0.7,
		shape = {
			type = "rectangle",
			x = 0,
			y = 0,
			width = 1024,
			height = 4
		}
	}
	
	return self
end

function puzzle(options)
	local self = Entity.create(options)
	
	local pieces = {
		{
			image = "tl.png",
			x = 128,
			y = 128,
			angle = 1
		},
		{
			image = "bl.png",
			x = 128,
			y = 384,
			angle = -1
		},
		{
			image = "tr.png",
			x = 384,
			y = 128,
			angle = 2
		},
		{
			image = "br.png",
			x = 384,
			y = 384,
			angle = 2
		}
	}
	
	local piece = pieces[self.piece]
	
	self.logicalAngle = piece.angle
	self.angle = self.logicalAngle * math.pi / 2
	
	self.components.sprite = SpriteComponent.create{
		file = piece.image,
		x = piece.x,
		y = piece.y,
		layer = 2
	}
	
	self.components.logic = LogicComponent.create{
		startAction = function()
			self.logicalAngle = self.logicalAngle + 1
			if self.logicalAngle > 2 then
				self.logicalAngle = self.logicalAngle - 4
			end
			self.angle = self.logicalAngle * math.pi / 2
			
			local correct = true
			for _, piece in ipairs(game.puzzle) do
				if piece.logicalAngle ~= 0 then
					correct = false
				end
			end
			if correct then
				game.stars = 0
				game:addGFX("star", 640, 300, 0)
				game:addSFX("star")
			end
		end
	}
	
	game.stars = 1
	game.puzzle[self.piece] = self
	
	return self
end

function spring(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "spring.png",
		x = 256,
		y = 32,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		shape = {
			type = "rectangle",
			x = 0,
			y = -16,
			width = 512,
			height = 32
		}
	}
	
	return self
end

function star(options)
	local self = Entity.create(options)
	
	self.static = true
	self.sensor = true
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "star.png",
		x = 32,
		y = 32,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		bullet = true,
		shape = {
			type = "circle",
			x = 0,
			y = 0,
			radius = 30
		}
	}
	
	self.components.logic = LogicComponent.create{
		addContact = function(component, entity, contact, reverse)
			game:removeEntity(self)
			--[[
			local nx, ny = contact:getNormal()
			local vx, vy = contact:getVelocity()
			if reverse then
				nx, ny = -nx, -ny
				vx, vy = -vx, -vy
			end
			local body = entity.components.body.body
			--body:setPosition(nx * contact:getSeparation(), ny * contact:getSeparation())
			body:setLinearVelocity(vx, vy)
			]]
			game.stars = game.stars - 1
			game:addGFX("star", self.x, self.y, self.angle)
			game:addSFX("star")
		end
	}
	
	game.stars = game.stars + 1
	
	return self
end

function staticPlank(options)
	local self = Entity.create(options)
	
	self.static = true
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "staticPlank.png",
		x = 64,
		y = 8,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		shape = {
			type = "rectangle",
			x = 0,
			y = 0,
			width = 128,
			height = 16
		}
	}
	
	return self
end

function triangle(options)
	local self = Entity.create(options)
	
	self.static = true
	
	if not self.angle then
		self.angle = 0
	end
	
	self.components.sprite = SpriteComponent.create{
		file = "triangle.png",
		x = 32,
		y = 16,
		layer = 1
	}
	
	self.components.body = BodyComponent.create{
		shape = {
			type = "polygon",
			points = {
				-32, 16,
				32, 16,
				32, -16,
				0, 0
			}
		}
	}
	
	return self
end

function ufo(options)
	local self = Entity.create(options)
	
	if not self.angle then
		self.angle = 0
	end
	
	local targetX, targetY = self.x, self.y
	
	self.components.sprite = SpriteComponent.create{
		file = "ufo.png",
		x = 128,
		y = 64,
		layer = 2
	}
	
	self.components.body = BodyComponent.create{
		fixedRotation = true,
		shape = {
			type = "polygon",
			points = {
				14, -33,
				42, -14,
				91, 7,
				16, 27,
				-16, 27,
				-91, 7,
				-42, -14,
				-14, -33
			}
		},
		beforePhysics = function(component, dt)
			local x, y = component.body:getPosition()
			local speed = 200 * dt
			if x > targetX + speed then
				component.body:setX(x - speed)
			elseif x < targetX - speed then
				component.body:setX(x + speed)
			else
				component.body:setX(targetX)
			end
			if y > targetY then 
				component.body:applyForce(0, (targetY - y) * 0.2)
			end
		end
	}
	
	self.components.logic = LogicComponent.create{
		addContact = function(component, entity)
			if not entity.sensor then
				game:removeEntity(self)
				game:addGFX("explosion", self.x, self.y, self.angle)
				game:addSFX("explosion")
				game:trigger("explodedNearby", self, 10)
			end
		end,
		fireworkLaunched = function(component, x)
			if x > self.x - 64 and x < self.x + 140 then
				targetX = x + 200
			elseif x <= self.x - 64 and x > self.x - 140 then
				targetX = x - 200
			end
		end
	}
	
	return self
end
