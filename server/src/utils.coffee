Function.prototype.curry = Function.prototype.curry or (args...) ->
	if args.length is 0 then return this
	origFunc = this
	return (newArgs...) ->
		origFunc.apply(this, args.concat(newArgs))