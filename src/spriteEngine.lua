require("src/spriteComponent")

local LAYERS = 4

spriteEngine = {
	layers = {}
}

for i = 1, LAYERS do
	spriteEngine.layers[i] = {}
end

function spriteEngine:registerSprite(sprite)
	self.layers[sprite.layer or LAYERS][sprite] = true
end

function spriteEngine:unregisterSprite(sprite)
	self.layers[sprite.layer or LAYERS][sprite] = nil
end

function spriteEngine:render()
	for i = 1, LAYERS do
		for s in pairs(self.layers[i]) do
			s:render()
		end
	end
end