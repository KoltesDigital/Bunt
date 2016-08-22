local colors = {
	red = {255, 0, 0},
	green = {0, 255, 0},
	blue = {0, 0, 255},
	yellow = {255, 255, 0}
}

SpriteComponent = {}
SpriteComponent.__index = SpriteComponent

function SpriteComponent.create(fields)
	local self = fields or {}
	setmetatable(self, SpriteComponent)
	
	return self
end

function SpriteComponent:addToEntity(entity)
	self.entity = entity
	self:setSprite(self.file)
	spriteEngine:registerSprite(self)
end

function SpriteComponent:removeFromEntity()
	spriteEngine:unregisterSprite(self)
	self.image = nil
	self.entity = nil
end

function SpriteComponent:setSprite(file)
	self.file = file
	self.image = love.graphics.newImage(constants.dataPath .. "images/" .. file)
end

function SpriteComponent:refreshAssets()
	self:setSprite(self.file)
end

function SpriteComponent:render()
	if self.entity.color then
		love.graphics.setColor(unpack(colors[self.entity.color] or self.entity.color))
	else
		love.graphics.setColor(255, 255, 255)
	end
	love.graphics.draw(self.image, self.entity.x, self.entity.y, self.entity.angle, (self.entity.scaleX or 1) * (self.entity.reverse and -1 or 1), (self.entity.scaleY or 1), self.x, self.y)
end
