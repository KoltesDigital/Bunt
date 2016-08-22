Entity = {}
Entity.__index = Entity

function Entity.create(options)
	local self = options or {}
	setmetatable(self, Entity)
	
	if type(self.components) ~= "table" then
		self.components = {}
	end
	
	return self
end

function Entity:addToScene()
	return self:trigger("addToEntity", self)
end

function Entity:removeFromScene()
	return self:trigger("removeFromEntity", self)
end

function Entity:trigger(event, ...)
	--print("event", self.id, event, ...)
	--if self[event] then
	--	self[event](self, ...)
	--end
	
	for _, component in pairs(self.components) do
		local handler = component[event]
		if handler then
			handler(component, ...)
		end
	end
end
