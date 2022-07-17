--
return [[
	All vfs implementation instances must implement cc:tweaked fs api.
	The modules themselves must offer a simple `mod.create` function that creates the API. 
		it can take any # of parameters, and must return an instance (which can contain more FS)
]]
