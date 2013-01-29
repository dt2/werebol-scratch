inBrowser = typeof window != "undefined"
haveNode = typeof process != "undefined"

if haveNode
	spawn = require('child_process').spawn

g_id = 0

G = (name) ->
	this.log = []
	this.start = new Date()
	this.id = ++ g_id
	this.name = name
	this

g = new G("main")

main = () ->
	log "main"
	log "Have #{ if haveNode then "nodejs" else "no nodejs" }"
	log "spawning"
	
	process.nextTick task "child", () ->	
		ls = spawn "./r3", ["-cs","hello.r3"]
	
		ls.stdout.on "data", (data) ->
		  log "stdout: " + data

		ls.stderr.on "data", (data) ->
		  log "stderr: " + data

		ls.on "exit", (code) ->
		  plog "child process exited with code " + code

	plog "done"
	
	
plog = (o) ->
	if o != undefined then log o
	d = new Date()
	header = "task: #{g.id}, #{g.desc} @#{d}"
	console.log header
	console.log g.log
	if inBrowser then $("#log").append "#{header}\n:#{g.log}\n"
	g.log = ["..."]

log = (o) ->
	g.log.push o
	
callout = (f, go = g) ->
	f.g = go
	(args...) ->
		g = f.g
		try f args... catch e
			console.log e.stack
			log e
			plog()
			return
		
task = (name,f) ->
	callout f, new G(name)
	
			
#last!
do callout () ->
	if inBrowser then Zepto main else do main
		
		




