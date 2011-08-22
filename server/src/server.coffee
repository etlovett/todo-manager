# core modules
fs = require("fs")
http = require("http")

# other packages
express = require("express")

# local modules
TodoList = require("./todoList")
Todo = require("./todo")
utils = require("./utils")


# 
# Helper methods
# 

writeTodos = (filepath, todoList, callback) ->
	todoString = todoList.asJsonString()
	fs.writeFile(filepath, todoString, "utf8", callback)

readTodos = (filepath, callback) ->
	fs.readFile(filepath, "utf8", (error, data) ->
		if error
			callback(error)
		else
			todoList = TodoList.constructFromJsonString(data)
			callback(error, todoList)
	)

parseTodoId = (request, response, next) ->
	todoIdString = request.params.todoId
	
	if todoIdString.match(/^[0-9]+$/)
		request.todoId = parseInt(todoIdString, 10)
		next()
	else
		response.send( error: "invalid id", 400 )

ensureTodoExistsForId = (todoList, request, response, next) ->
	if todoList.todoExists(request.todoId)
		next()
	else
		response.send( error: "no todo exists at that id", 400 )


#
# Start up the server
#

# wrap this so that the globals (todoFile and todoArray) don't pollute the helper methods above
(() ->
	
	#
	# Set up our globals
	#
	todoFile = "./todo.txt"
	todoList = new TodoList()
	
	
	#
	# Start watching the file, and ensure that we stop watching it when we go down
	#
	fs.watchFile(todoFile, (currStat, prevStat) ->
		if currStat.mtime.getTime() isnt prevStat.mtime.getTime()
			console.log("file changed externally!")
			readTodos(todoFile, (error, newTodoList) ->
				todoList = newTodoList
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
	readTodos(todoFile, (error, newTodoList) ->
		if error then throw error
		
		console.log("read!")
		
		todoList = newTodoList
		
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
			response.send(todoList.asRawObject())
		)
		
		# create a new todo and persist the update
		server.post(todosPath, (request, response) ->
			if not fields.todo
				response.send( error: "must include a todo property to create a new todo", 400 )
			
			newTodo = new Todo(fields)
			index = request.body?.index ? -1
			todoList.add(newTodo, index)
			
			writeTodos(todoFile, todoList, (error) ->
				if error
					response.send(error)
				else
					response.send({ returnValue: true, todo: newTodo.asRawObject() } )
			)
		)
		
		# get a single todo
		server.get(singleTodoPath, parseTodoId, ensureTodoExistsForId.curry(todoList), (request, response) ->
			response.send(todoList.get(request.todoId))
		)
		
		# update a single todo and persist the update
		server.post(singleTodoPath, parseTodoId, ensureTodoExistsForId.curry(todoList), (request, response) ->
			todoId = request.todoId
			todo = todoList.get(todoId)
			todo.update(request.body)
			
			writeTodos(todoFile, todoList, (error) ->
				if error
					response.send(error)
				else
					response.send({ returnValue: true, todo: todo.asRawObject() } )
			)
		)
		
		server.listen(5834, () -> console.log("listening!") )
	)
	
)()