# core modules
fs = require("fs")

# local modules
TodoList = require("./todoList")

class FileBasedTodoList extends TodoList
	# 
	# Static methods and properties
	# 
	@FILE_ENCODING: "utf8"
	
	# 
	# Instance methods
	# 
	constructor: (@filename = "todo.txt", todoArray, todos...) ->
		@_filename = filename
		@_watchingFile = false
		super(todoArray, todos...)
	
	readFromFile: (callback) ->
		fs.readFile(@filename, FileBasedTodoList.FILE_ENCODING, (error, data) =>
			if error
				callback(error)
			else
				todoArray = TodoList.parseFileData(data)
				@_doReset(todoArray)
				callback(error)
		)
	
	writeToFile: (callback) ->
		todoString = @asJsonString()
		fs.writeFile(@filename, todoString, FileBasedTodoList.FILE_ENCODING, callback)
	
	startWatchingFile: () ->
		if not @watchingFile
			fs.watchFile(@filename, (currStat, prevStat) =>
				if currStat.mtime.getTime() isnt prevStat.mtime.getTime()
					console.log("file changed!")
					# NOTE: we re-read the file even when we're the ones that just updated it.
					#		this is bad, but there's no way to know when it was us and when it was something else
					@readFromFile( (error) =>
						if error then throw error
					)
			)
			@watchingFile = true
	
	stopWatchingFile: () ->
		if @watchingFile
			fs.unwatchFile(@filename)
			@watchingFile = false
	
	reset: (args..., callback) ->
		super(args...)
		@writeToFile(callback)
	
	add: (args..., callback) ->
		todo = super(args...)
		@writeToFile( (error) =>
			callback(error, todo)
		)
	
	update: (args..., callback) ->
		todo = super(args...)
		@writeToFile( (error) =>
			callback(error, todo)
		)

	del: (args..., callback) ->
		todo = super(args...)
		@writeToFile( (error) =>
			callback(error, todo)
		)


# 
# Exports
# 
module.exports = FileBasedTodoList
