return {
	next = "car2.lua"
}, {
	balloon{
		name = "b1",
		color = "blue",
		x = 618,
		y = 300
	},
	
	balloon{
		name = "b2",
		color = "yellow",
		x = 662,
		y = 300
	},
	
	crate{
		name = "c",
		x = 640,
		y = 350
	},
	
	staticPlank{
		x = 640,
		y = 150
	},
	
	star{
		x = 640,
		y = 500
	}
}, {
	{
		type = "revolute",
		a = "b1",
		b = "c",
		x = 618,
		y = 325
	},
	{
		type = "revolute",
		a = "b2",
		b = "c",
		x = 662,
		y = 325
	}
}