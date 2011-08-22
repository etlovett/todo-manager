{spawn, exec} = require "child_process"

spawnChild = (command, options, callback) ->
	child = spawn command, options
	child.stdout.on "data", (data) -> process.stdout.write data.toString()
	child.stderr.on "data", (data) -> process.stderr.write data.toString()
	process.on "SIGHUP", () -> child.kill()
	process.on "SIGINT", () -> child.kill()
	child.on "exit", (status) -> callback?(status)
	return child

build = (watch, callback) ->
	if typeof watch is "function"
		callback = watch
		watch = false
	serverOptions = ["-c", "-o", "server/lib/", "server/src/"]
	clientOptions = ["-c", "-o", "client/lib/", "client/src/"]
	if watch
		serverOptions.unshift "-w"
		clientOptions.unshift "-w"
	
	oneDone = false
	intermediateCallback = (status) ->
		if oneDone
			callback?(status)
		else
			oneDone = true
	spawnChild "coffee", serverOptions, intermediateCallback
	spawnChild "coffee", clientOptions, intermediateCallback

task "build", "Compile CoffeeScript source files", ->
	build()

task "watch", "Recompile CoffeeScript source files when modified", ->
	build true

task "start", "Start server", ->
	spawnChild "node", ["server/lib/server.js"]
