return {
	next = "car.lua"
}, {
	frog{
		color = "green",
		x = 640,
		y = 500
	},
	
	spring{
		name = "s",
		x = 640,
		y = 616
	},
	
	star{
		x = 640,
		y = 180
	}
}, {
	{
		type = "distance",
		a = "s",
		x1 = 400,
		y1 = 600,
		x2 = 880,
		y2 = 648,
		f = 1
	},
	{
		type = "distance",
		a = "s",
		x1 = 880,
		y1 = 600,
		x2 = 400,
		y2 = 648,
		f = 1
	}
}