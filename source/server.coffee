# core modules
http = require("http")

# other packages
express = require("express")

# local modules
TodoList = require("./todoList")
FileBasedTodoList = require("./fileBasedTodoList")
Todo = require("./todo")


# 
# Helper methods
# 

parseTodoId = (request, response, next) ->
	todoIdString = request.params.todoId
	
	if todoIdString.match(/^[0-9]+$/)
		request.todoId = parseInt(todoIdString, 10)
		next()
	else
		response.send( error: "invalid id", 400 )

ensureTodoExistsForId = (request, response, next) ->
	# NOTE: this references the global todoList
	if todoList.todoExists(request.todoId)
		next()
	else
		response.send( error: "no todo exists at that id", 400 )


#
# Set up our globals
#
todoList = new FileBasedTodoList("./todo.txt")


#
# Start watching the file, and ensure that we stop watching it when we go down
#
todoList.startWatchingFile()
process.on("exit", () ->
	console.log("exiting!")
	todoList.stopWatchingFile()
)
process.on("SIGINT", () ->
	console.log("SIGINT!")
	# call process.exit so that we get the exit event for cleanup
	process.exit()
)


#
# Do the initial read of the file and start up the server
#
todoList.readFromFile( (error) ->
	if error then throw error
	
	console.log("read!")
	
	server = express.createServer()
	server.configure(() -> 
		server.use(express.logger("dev"))
		server.use(express.favicon())
		server.use(express.bodyParser())
		server.use(server.router)
		server.use(express.static(__dirname + "/../static", { maxAge: 24 * 60 * 60 * 1000 }))
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
		if not Todo.isValidRawTodo(fields.todo)
			response.send( error: "must include a todo property to create a new todo", 400 )
		
		todoList.add(fields, request.body?.index, (error, addedTodo) ->
			if error
				response.send(error)
			else
				response.send({ returnValue: true, todo: addedTodo.asRawObject() } )
		)
	)
	
	# get a single todo
	server.get(singleTodoPath, parseTodoId, ensureTodoExistsForId, (request, response) ->
		response.send(todoList.get(request.todoId))
	)
	
	# update a single todo and persist the update
	server.post(singleTodoPath, parseTodoId, ensureTodoExistsForId, (request, response) ->
		todoList.update(request.todoId, request.body, (error, updatedTodo) ->
			if error
				response.send(error)
			else
				response.send({ returnValue: true, todo: updatedTodo.asRawObject() } )
		)
	)
	
	server.listen(5834, () -> console.log("listening!") )
)
