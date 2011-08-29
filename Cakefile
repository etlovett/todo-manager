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
	options = ["-c", "-o", "build/", "source/"]
	if watch
		options.unshift "-w"
	
	spawnChild "coffee", options, callback

task "build", "Compile CoffeeScript source files", () ->
	build()

task "watch", "Recompile CoffeeScript source files when modified", () ->
	build true

task "start", "Start server", () ->
	build false, (status) ->
		if status is 0 then spawnChild "node", ["build/server.js"]
