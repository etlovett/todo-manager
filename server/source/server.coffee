fs = require("fs")
http = require("http")
express = require("express")


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
		response.send( error: "invalid id" )

ensureTodoExistsForId = (todoArray, request, response, next) ->
	if todoArray[request.todoId]
		next()
	else
		response.send( error: "invalid id" )

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

# wrap this so that the psuedo-globals (todoFile and todoArray) don't pollute the helper methods above
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
		fs.unwatchFile(todoFile)
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
		
		server.get("/todos", (request, response) ->
			response.send(todoArray)
		)
		
		singleTodoPath = "/todo/:todoId"
		server.get(singleTodoPath, parseTodoId, ensureTodoExistsForId.bind(undefined, todoArray), (request, response) ->
			response.send(todoArray[request.todoId])
		)
		
		server.post(singleTodoPath, parseTodoId, ensureTodoExistsForId.bind(undefined, todoArray), (request, response) ->
			todoId = request.todoId
			todoArray[todoId] = updateTodo(todoArray[todoId], request.body)
			
			writeTodos(todoFile, todoArray, (error) ->
				if error
					response.send(error)
				else
					response.send( returnValue: true )
			)
		)
		
		server.listen(5834, () ->
			console.log("listening!")
		)
	)
	
)()