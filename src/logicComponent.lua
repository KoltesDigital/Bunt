LogicComponent = {}
LogicComponent.__index = LogicComponent

function LogicComponent.create(fields)
	local self = fields or {}
	setmetatable(self, LogicComponent)
	return self
end

function LogicComponent:addToEntity(entity)
	self.entity = entity
end

function LogicComponent:removeFromEntity()
	self.entity = nil
end
