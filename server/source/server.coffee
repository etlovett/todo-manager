fs = require("fs")
http = require("http")


# 
# Helper methods
# 
deserializeTodos = (fileString) ->
	todoArray = fileString.split(/[\n\r]+/g)
	
	todoArray = todoArray.map( (todoString) ->
		if not todoString then return null
		
		match = todoString.match(/^([0-9]+)[^a-zA-Z0-9]{0,2}\s*(.*)$/i)
		
		if not match then return null
		
		return {
			index: match[1],
			todo: match[2]
		}
	, this)
	
	todoArray = todoArray.filter( (todoObj) ->
		return !!todoObj
	, this)
	
	return todoArray

normalizeTodos = (todoArray) ->
	if not Array.isArray(todoArray)
		throw new Error("normalizeTodos: todoArray must be an array!")
	
	todoArray = sortTodos(todoArray)
	todoArray = todoArray.map( (curTodo, index) ->
		return {
			index: index + 1,
			todo: curTodo.todo
		}
	, this)
	
	return todoArray

serializeTodos = (todoArray) ->
	if not Array.isArray(todoArray)
		throw new Error("serializeTodos: todoArray must be an array!")
	
	todoArray = sortTodos(todoArray)
	
	todoString = todoArray.reduce( (acc, curTodo) ->
		return acc + curTodo.index + ". " + curTodo.todo + "\n"
	, "")
	
	return todoString

sortTodos = (todoArray) ->
	return todoArray.sort( (todo1, todo2) ->
		return (todo1.index - todo2.index)
	)


# 
# Start up the server
# 

todoFile = "./todo.txt"
todoFileOut = "./todo2.txt"

fs.readFile(todoFile, "utf8", (error, data) ->
	if error then throw error
	
	console.log("read!")
	
	todoArray = deserializeTodos(data)
	todoArray = normalizeTodos(todoArray)
	
	http.createServer( (request, response) ->
		if (request.method is "GET")
			response.writeHead(200, {
				"content-type": "application/json"
			})
			response.write(JSON.stringify(todoArray))
			response.end("\n")
		else if (request.method is "POST")
			response.end("sweet! \n")
		else
			response.statusCode = 405
			response.end("Only GET and POST are supported")
	).listen(5834, () ->
		console.log("listening!")
	)
	
	# todoString = serializeTodos(todoArray)
	# fs.writeFile(todoFileOut, todoString, "utf8", (error) ->
	# 	if error then throw error
	# 	
	# 	console.log("written!")
	# )
)
