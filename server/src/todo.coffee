class Todo
	# 
	# Static methods and properties
	# 
	@IMPORTANCE:
		LOW: 
			CHAR: "-"
			VALUE: -1
		REGULAR: 
			CHAR: ""
			VALUE: 0
		HIGH: 
			CHAR: "!"
			VALUE: 1
	
	@importanceValueFromChar: (importanceChar) ->
		for own importanceObjName, importanceObj of Todo.IMPORTANCE
			if importanceObj.CHAR is importanceChar
				return importanceObj.VALUE
		return Todo.IMPORTANCE.REGULAR.VALUE

	@importanceCharFromValue: (importanceValue) ->
		for own importanceObjName, importanceObj of Todo.IMPORTANCE
			if importanceObj.VALUE is importanceValue
				return importanceObj.CHAR
		return Todo.IMPORTANCE.REGULAR.CHAR
	
	@isValidRawTodo: (fields) ->
		# TODO: check more properties for validity?
		return !!fields.todo and typeof fields.todo is "string"
	
	# 
	# Instance methods
	# 
	
	# accepts both separate arguments and an object containing the properties
	constructor: (todo, importance) ->
		@todo = ""
		@importance = 0
		@update(todo, importance)
	
	# accepts both separate arguments and an object containing the properties
	update: (todo, importance) ->
		# TODO: check the incoming properties for validity
		if typeof todo is "string"
			@todo = todo ? @todo
			@importance = parseInt(importance, 10) ? @importance ? 0
		else if todo
			@todo = todo.todo ? @todo
			@importance = parseInt(todo.importance, 10) ? @importance ? 0
		else
			throw new Error("falsy todo!")
	
	importanceAsChar: () ->
		return Todo.importanceCharFromValue(@importance)
	
	asRawObject: () ->
		return {
			todo: @todo
			importance: @importance
		}

# 
# Exports
# 
module.exports = Todo
