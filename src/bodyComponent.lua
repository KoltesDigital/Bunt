BodyComponent = {}
BodyComponent.__index = BodyComponent

function BodyComponent.create(fields)
	local self = fields or {}
	setmetatable(self, BodyComponent)
	
	return self
end

function BodyComponent:addToEntity(entity)
	self.entity = entity
	
	self:createBody()
	
	if self.speed then
		self.body:setLinearVelocity(self.speed * math.cos(entity.angle), self.speed * math.sin(entity.angle))
	end
	--spriteEngine:registerSprite(self)
end

function BodyComponent:removeFromEntity()
	--spriteEngine:unregisterSprite(self)
	self:removeBody()
	self.entity = nil
end

function BodyComponent:setShape(shape)
	self.shape = shape
	if self.body then
		self:removeBody()
		self:createBody()
	end
end

function BodyComponent:createBody()
	self.body = love.physics.newBody(world, self.entity.x, self.entity.y, 0, 0)
	
	if self.fixedRotation then
		self.body:setFixedRotation(self.fixedRotation)
	end
		
	if self.shape.type == "circle" then
		self.s = love.physics.newCircleShape(self.body, self.shape.x * (self.entity.reverse and -1 or 1), self.shape.y, self.shape.radius)
	elseif self.shape.type == "rectangle" then
		self.s = love.physics.newRectangleShape(self.body, self.shape.x * (self.entity.reverse and -1 or 1), self.shape.y, self.shape.width, self.shape.height)
	elseif self.shape.type == "polygon" then
		local points = self.shape.points
		if self.entity.reverse then
			points = {}
			for i = 1, #self.shape.points, 2 do
				points[i] = - self.shape.points[i]
				points[i+1] = self.shape.points[i+1]
			end
		end
		self.s = love.physics.newPolygonShape(self.body, unpack(points))
	end
	self.s:setData(self.entity)
	
	if self.entity.sensor then
		self.s:setSensor(true)
	end
	
	if self.entity.static then
		self.body:setMass(0, 0, 0, 0)
		--self.body:putToSleep()
	else 
		self.body:setMassFromShapes()
		if self.mass then
			local mass = self.body:getMass()
			local mx, my = self.body:getLocalCenter()
			local inertia = self.body:getInertia()
			self.body:setMass(mx, my, self.mass, inertia * self.mass / mass)
		end
	end
	
	if self.bullet then
		self.body:setBullet(true)
	end
	
	if self.entity.angle then
		self.body:setAngle(self.entity.angle)
	end
	
	self.contacts = 0
end

deleteY = -1000
function BodyComponent:removeBody()
	self.body:setPosition(-2000, deleteY)
	deleteY = deleteY - 300
	if deleteY < -1000000 then
		deleteY = -1000
	end
	self.s:setData(self.body)
	game.bodiesToDelete[self.body] = self.contacts
	self.body = nil
end

function BodyComponent:updatePosition()
	self.entity.x = self.body:getX()
	self.entity.y = self.body:getY()
	self.entity.angle = self.body:getAngle()
end

function BodyComponent:setLinearVelocity(speed)
	if self.body then
		self.body:setLinearVelocity(speed * math.cos(self.entity.angle), speed * math.sin(self.entity.angle))
	end
end

function BodyComponent:addContact()
	self.contacts = self.contacts + 1
end

function BodyComponent:removeContact()
	self.contacts = self.contacts - 1
end

function BodyComponent:explodedNearby(entity, power)
	if self.entity ~= entity then
		local dx = self.entity.x - entity.x
		local dy = self.entity.y - entity.y
		local d2 = dx^2 + dy^2
		local d = d2^0.5
		local force = power / d2
		self.body:applyImpulse(force * dx / d, force * dy / d)
		self.body:applyTorque(math.random(-force, force)*1000)
	end
end

function BodyComponent:applyImpulse(fx, fy)
	if self.body then
		return self.body:applyImpulse(fx, fy)
	end
end

function BodyComponent:render()
	local x, y = self.body:getPosition()
	love.graphics.setColor(72, 160, 14, 128) -- set the drawing color to green for the ground
	if self.s.getPoints then
		love.graphics.polygon("fill", self.s:getPoints()) -- draw a "filled in" polygon using the ground's coordinates
  	end
	love.graphics.circle("fill", x, y, 5) 
end

function BodyComponent:afterPhysics()
	self:updatePosition()
end