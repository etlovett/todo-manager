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

importanceValueFromChar = (importanceChar = "") ->
	for own importanceObjName, importanceObj of TODO_IMPORTANCE
		if importanceObj.CHAR is importanceChar
			return importanceObj.VALUE

importanceCharFromValue = (importanceValue = 0) ->
	for own importanceObjName, importanceObj of TODO_IMPORTANCE
		if importanceObj.VALUE is importanceValue
			return importanceObj.CHAR

deserializeTodos = (fileString) ->
	todoArray = fileString.split(/[\n\r]+/g)
	
	# parse each line in the file
	todoArray = todoArray.map( (todoString) ->
		if not todoString then return null
		
		match = todoString.match(/^([0-9]+)[^a-zA-Z0-9]{0,2}\s+([!-])?\s*(.*)$/i)
		
		if not match then return null
		
		return {
			index: match[1],
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
			todo: curTodo.todo,
			importance: importanceValueFromChar(curTodo.importanceChar)
		}
	, this)
	
	return todoArray

serializeTodos = (todoArray) ->
	if not Array.isArray(todoArray)
		throw new Error("serializeTodos: todoArray must be an array!")
	
	return todoArray.reduce( (acc, curTodo, curIndex) -> 
		return acc + curIndex + ". " + importanceCharFromValue(curTodo.importance) + " " + curTodo.todo + "\n"
	, "")


# 
# Start up the server
# 

todoFile = "./todo.txt"
todoFileOut = "./todo2.txt"

fs.readFile(todoFile, "utf8", (error, data) ->
	if error then throw error
	
	console.log("read!")
	
	todoArray = deserializeTodos(data)
	
	server = express.createServer();
	server.configure(() ->
		server.use(express.bodyParser());
		# server.use(express.methodOverride());
		# server.use(server.router);
	);
	
	server.get("/todos", (request, response) ->
		console.log("get todos")
		response.send(todoArray)
	);
	
	server.get("/todo/:todoId([0-9]+)", (request, response) ->
		todoId = parseInt(request.params.todoId, 10)
		responseJSON = todoArray[todoId] ? { error: "invalid id" }
		response.send(responseJSON)
	);
	
	server.post("*", (request, response) ->
		console.log("post")
		response.send("sweet!")
	)
	
	server.all("*", (request, response) ->
		console.log("catch-all")
		console.log("a 404!  request url: " + JSON.stringify(request.url))
		response.send("What were you hoping for?", 404)
	)
	
	server.listen(5834, () ->
		console.log("listening!")
	);
	
	# todoString = serializeTodos(todoArray)
	# fs.writeFile(todoFileOut, todoString, "utf8", (error) ->
	# 	if error then throw error
	# 	
	# 	console.log("written!")
	# )
)
