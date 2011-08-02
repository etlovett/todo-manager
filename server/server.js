var fs = require("fs");

var todoFile = "./todo.txt";
var todoFileOut = "./todo2.txt";

fs.readFile(todoFile, "utf8", function (err, data) {
	if (err) {
		throw err;
	}
	
	console.log("read!");
	
	var todoArray = deserializeTodos(data);
	todoArray = normalizeTodos(todoArray);
	
	var todoString = serializeTodos(todoArray);
	fs.writeFile(todoFileOut, todoString, "utf8", function (err) {
		if (err) {
			throw err;
		}
		
		console.log("written!");
	});
});


function deserializeTodos(fileString) {
	var todoArray = fileString.split(/[\n\r]+/g);
	
	todoArray = todoArray.map(function (todoString) {
		if (!todoString) {
			return null;
		}
		
		var match = todoString.match(/^([0-9]+)\.?\s*(.*)$/i);
		
		if (!todoString) {
			return null;
		}
		
		return {
			index: match[1],
			todo: match[2]
		};
	});
	
	todoArray = todoArray.filter(function (todoObj) {
		return !!todoObj;
	});
	
	return todoArray;
}

function normalizeTodos(todoArray) {
	if (!Array.isArray(todoArray)) {
		throw new Error("normalizeTodos: todoArray must be an array!");
	}
	
	//TODO: this
	
	return todoArray;
}

function serializeTodos(todoArray) {
	if (!Array.isArray(todoArray)) {
		throw new Error("serializeTodos: todoArray must be an array!");
	}
	
	todoArray = todoArray.sort(function (todo1, todo2) {
		return (todo1.index - todo2.index);
	});
	
	var todoString = todoArray.reduce(function (acc, curTodo) {
		return acc + curTodo.index + ". " + curTodo.todo + "\n";
	}, "");
	
	return todoString;
}
