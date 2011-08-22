Todo = require("./todo")

class TodoList
	# 
	# Static methods and properties
	# 
	@parseFileData: (fileData) ->
		todoArray = fileData.split(/[\n\r]+/g)
		
		# parse each line in the file
		todoArray = todoArray.map( (todoString) =>
			if not todoString then return null
			
			match = todoString.match(/^([0-9]+)[^a-zA-Z0-9]{0,2}\s+([!-])?\s*(.*)$/i)
			
			if not match then return null
			
			return {
				index: match[1]
				importanceChar: match[2]
				todo: match[3]
			}
		)
		
		# filter out any blank lines
		todoArray = todoArray.filter( (todoObj) => return !!todoObj)
		
		# sort the array based on the index specified
		todoArray = todoArray.sort( (todo1, todo2) =>
			return (todo1.index - todo2.index)
		)
		
		# create the actual array of objects we will be using throughout the system
		todoArray = todoArray.map( (curTodo, index) =>
			return {
				todo: curTodo.todo
				importance: Todo.importanceValueFromChar(curTodo.importanceChar)
			}
		)
		
		return todoArray
	
	
	# 
	# Instance methods
	# 
	constructor: (todoArray, todos...) ->
		@_list = []
		@_doReset(todoArray, todos...)
	
	reset: (todoArray, todos...) ->
		@_doReset(todoArray, todos...)
	
	add: (todo, index) ->
		return @_doAdd(todo, index)
	
	get: (index) ->
		return @_list[index]
	
	update: (index, newFields) ->
		todo = @_list[index]
		todo.update(newFields)
		return todo
	
	todoExists: (index) ->
		return not not @get(index)
	
	length: () ->
		return @_list.length
	
	asRawObject: () ->
		return (todo.asRawObject() for todo in @_list)
	
	asJsonString: () ->
		return @asRawObject().reduce( (acc, curTodo, curIndex) -> 
			# must use "or" here instead of "?" because the empty string doesn't fail the "?" test
			importanceChar = Todo.importanceCharFromValue(curTodo.importance) or " "
			return acc + curIndex + ". " + importanceChar + " " + curTodo.todo + "\n"
		, "")
	
	_doReset: (todoArray, todos...) ->
		@_list = []
		# accept both a single array and separate arguments
		if Array.isArray(todoArray)
			@_doAdd(todo) for todo in todoArray
		else if todoArray
			@_doAdd(todo) for todo in [todoArray, todos...]
	
	_doAdd: (todo, index) ->
		if not (todo instanceof Todo)
			todo = new Todo(todo)
		
		if index? and 0 < index < @_list.length
			@_list.splice(index, 0, todo)
		else
			@_list.push(todo)
		
		return todo
	

# 
# Exports
# 
module.exports = TodoList
