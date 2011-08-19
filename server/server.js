var fs = require("fs");
var http = require("http");

var todoFile = "./todo.txt";
var todoFileOut = "./todo2.txt";

fs.readFile(todoFile, "utf8", function (err, data) {
	if (err) {
		throw err;
	}
	
	console.log("read!");
	
	var todoArray = deserializeTodos(data);
	todoArray = normalizeTodos(todoArray);
	
	http.createServer(function (request, response) {
		if (request.method === "GET") {
			response.writeHead(200, {
				"content-type": "application/json"
			});
			response.write(JSON.stringify(todoArray));
			response.end("\n");
		} else if (request.method === "POST") {
			response.end("sweet! \n");
		} else {
			response.statusCode = 405;
			response.end("Only GET and POST are supported");
		}
	}).listen(5834, function () {
		console.log("listening!");
	});
	
	// var todoString = serializeTodos(todoArray);
	// fs.writeFile(todoFileOut, todoString, "utf8", function (err) {
	// 	if (err) {
	// 		throw err;
	// 	}
	// 	
	// 	console.log("written!");
	// });
});


function deserializeTodos(fileString) {
	var todoArray = fileString.split(/[\n\r]+/g);
	
	todoArray = todoArray.map(function (todoString) {
		if (!todoString) {
			return null;
		}
		
		var match = todoString.match(/^([0-9]+)[^a-zA-Z0-9]{0,2}\s*(.*)$/i);
		
		if (!todoString) {
			return null;
		}
		
		return {
			index: match[1],
			todo: match[2]
		};
	}, this);
	
	todoArray = todoArray.filter(function (todoObj) {
		return !!todoObj;
	}, this);
	
	return todoArray;
}

function normalizeTodos(todoArray) {
	if (!Array.isArray(todoArray)) {
		throw new Error("normalizeTodos: todoArray must be an array!");
	}
	
	todoArray = sortTodos(todoArray);
	todoArray = todoArray.map(function (curTodo, index) {
		return {
			index: index + 1,
			todo: curTodo.todo
		}
	}, this);
	
	return todoArray;
}

function serializeTodos(todoArray) {
	if (!Array.isArray(todoArray)) {
		throw new Error("serializeTodos: todoArray must be an array!");
	}
	
	todoArray = sortTodos(todoArray);
	
	var todoString = todoArray.reduce(function (acc, curTodo) {
		return acc + curTodo.index + ". " + curTodo.todo + "\n";
	}, "");
	
	return todoString;
}

function sortTodos(todoArray) {
	return todoArray.sort(function (todo1, todo2) {
		return (todo1.index - todo2.index);
	});
}
