fs = require("fs")
http = require("http")
express = require("express")
utils = require("./utils")


# 
# Constants
# 

TODO_IMPORTANCE = 
	LOW: 
		CHAR: "-"
		VALUE: -1
	REGULAR: 
		CHAR: ""
		VALUE: 0
	HIGH: 
		CHAR: "!"
		VALUE: 1


# 
# Helper methods
# 

importanceValueFromChar = (importanceChar) ->
	for own importanceObjName, importanceObj of TODO_IMPORTANCE
		if importanceObj.CHAR is importanceChar
			return importanceObj.VALUE
	return TODO_IMPORTANCE.REGULAR.VALUE

importanceCharFromValue = (importanceValue) ->
	for own importanceObjName, importanceObj of TODO_IMPORTANCE
		if importanceObj.VALUE is importanceValue
			return importanceObj.CHAR
	return TODO_IMPORTANCE.REGULAR.CHAR

deserializeTodos = (fileString) ->
	todoArray = fileString.split(/[\n\r]+/g)
	
	# parse each line in the file
	todoArray = todoArray.map( (todoString) ->
		if not todoString then return null
		
		match = todoString.match(/^([0-9]+)[^a-zA-Z0-9]{0,2}\s+([!-])?\s*(.*)$/i)
		
		if not match then return null
		
		return {
			index: match[1]
			importanceChar: match[2]
			todo: match[3]
		}
	, this)
	
	# filter out any blank lines
	todoArray = todoArray.filter( (todoObj) -> return !!todoObj)
	
	# sort the array based on the index specified
	todoArray = todoArray.sort( (todo1, todo2) ->
		return (todo1.index - todo2.index)
	)
	
	# create the actual array of objects we will be using throughout the system
	todoArray = todoArray.map( (curTodo, index) ->
		return {
			todo: curTodo.todo
			importance: importanceValueFromChar(curTodo.importanceChar)
		}
	, this)
	
	return todoArray

serializeTodos = (todoArray) ->
	if not Array.isArray(todoArray)
		throw new Error("serializeTodos: todoArray must be an array!")
	
	return todoArray.reduce( (acc, curTodo, curIndex) -> 
		# must use "or" here instead of "?" because the empty string doesn't fail the "?" test
		importanceChar = importanceCharFromValue(curTodo.importance) or " "
		return acc + curIndex + ". " + importanceChar + " " + curTodo.todo + "\n"
	, "")

parseTodoId = (request, response, next) ->
	todoIdString = request.params.todoId
	
	if todoIdString.match(/^[0-9]+$/)
		request.todoId = parseInt(todoIdString, 10)
		next()
	else
		response.send( error: "invalid id", 400 )

ensureTodoExistsForId = (todoArray, request, response, next) ->
	if todoArray[request.todoId]
		next()
	else
		response.send( error: "no todo exists at that id", 400 )

createTodo = (newFields) ->
	if not newFields.todo then return [false, {}]
	
	# TODO: check the incoming properties for validity
	newTodo = 
		todo: newFields.todo
		importance: parseInt(newFields.importance, 10) ? 0
	
	return [true, newTodo]

updateTodo = (todo, newFields) ->
	# TODO: check the incoming properties for validity
	todo.todo = newFields.todo ? todo.todo
	todo.importance = parseInt(newFields.importance, 10) ? todo.importance
	return todo

writeTodos = (filepath, todoArray, callback) ->
	todoString = serializeTodos(todoArray)
	fs.writeFile(filepath, todoString, "utf8", callback)

readTodos = (filepath, callback) ->
	fs.readFile(filepath, "utf8", (error, data) ->
		if error
			callback(error)
		else
			todoArray = deserializeTodos(data)
			callback(error, todoArray)
	)



#
# Start up the server
#

# wrap this so that the globals (todoFile and todoArray) don't pollute the helper methods above
(() ->
	
	#
	# Set up our globals
	#
	todoFile = "./todo.txt"
	todoArray = []
	
	
	#
	# Start watching the file, and ensure that we stop watching it when we go down
	#
	fs.watchFile(todoFile, (currStat, prevStat) ->
		if currStat.mtime.getTime() isnt prevStat.mtime.getTime()
			console.log("file changed externally!")
			readTodos(todoFile, (error, newTodoArray) ->
				todoArray = newTodoArray
			)
	)
	process.on("exit", () ->
		console.log("exiting!")
		fs.unwatchFile(todoFile)
	)
	process.on("SIGINT", () ->
		console.log("SIGINT!")
		# call process.exit so that we get the exit event for cleanup
		process.exit()
	)
	
	
	#
	# Do the initial read of the file and start up the server
	#
	readTodos(todoFile, (error, newTodoArray) ->
		if error then throw error
		
		console.log("read!")
		
		todoArray = newTodoArray
		
		server = express.createServer()
		server.configure(() -> 
			server.use(express.logger("dev"))
			server.use(express.favicon())
			server.use(express.bodyParser())
			server.use(server.router)
			# server.use(express.static(__dirname + "/../static", { maxAge: 24 * 60 * 60 * 1000 }))
			server.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
		)
		
		# paths supported
		todosPath = "/todos"
		singleTodoPath = todosPath + "/:todoId?"
		
		# get the whole list of todos
		server.get(todosPath, (request, response) ->
			response.send(todoArray)
		)
		
		# create a new todo
		server.post(todosPath, (request, response) ->
			[success, newTodo] = createTodo(request.body)
			if not success
				response.send( error: "must include a todo property to create a new todo", 400 )
			
			index = request.body?.index ? -1
			if index is -1
				todoArray.push(newTodo)
			else
				todoArray.splice(index, 0, newTodo)
			
			writeTodos(todoFile, todoArray, (error) ->
				if error
					response.send(error)
				else
					response.send({ returnValue: true, todo: newTodo } )
			)
		)
		
		server.get(singleTodoPath, parseTodoId, ensureTodoExistsForId.curry(todoArray), (request, response) ->
			response.send(todoArray[request.todoId])
		)
		
		server.post(singleTodoPath, parseTodoId, ensureTodoExistsForId.curry(todoArray), (request, response) ->
			todoId = request.todoId
			todoArray[todoId] = updateTodo(todoArray[todoId], request.body)
			
			writeTodos(todoFile, todoArray, (error) ->
				if error
					response.send(error)
				else
					response.send({ returnValue: true, todo: todoArray[todoId] } )
			)
		)
		
		server.listen(5834, () ->
			console.log("listening!")
		)
	)
	
)()