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
	
g = null

main = () ->
	log "Have #{ if haveNode then "nodejs" else "no nodejs" }"

	log "spawning"	
	ls = spawn "./r3", ["-cs","hello.r3"], {stdio: 'pipe'}
	log "feeding"
	ls.stdin.write "Ping\nPrepong\n"

	n = 0
	process.nextTick ticker = task "ticker", () ->
		++ n
		if n < 3
			log "> #{n}"
			ls.stdin.write "#{n}\n"				
			setTimeout ticker, 1000
		else
			log "> quit"			
			ls.stdin.write "quit\n"
		plog()
			
	process.nextTick task "listen", () ->			
		
		buf = ""
		
		ls.stdout.on "data", callout (data) ->
			#log "stdout: " + data
			buf += data
			log "buf: #{buf}"
			while m = buf.match /(.*?)\n([^]*)/m
				log "#{m[1]} --- #{m[2]}"
				buf = m[2]
			plog()		

		ls.stderr.on "data", callout (data) ->
		  plog "stderr: " + data

		ls.on "exit", callout (code) ->
		  plog "child done res: " + code

	plog "done"
	
	
plog = (o) ->
	if o != undefined then log o
	d = new Date()
	header = "task: #{g.id}, #{g.name} @#{d}"
	console.log header
	console.log g.log
	if inBrowser then $("#log").append "#{header}\n:#{g.log}\n"
	g.log = ["..."]

log = (o) ->
	g.log.push o
	
callout = (f, go = g) ->
	f.g = go
	(args...) ->
		if g
			throw new Exception "task runs in task!"
		g = f.g
		try f args... catch e
			console.log e.stack
			log e
			plog()
			g = null
			return
		g = null
		
task = (name,f) ->
	callout f, new G(name)
	
			
#last!
do task "main", () ->
	if inBrowser then Zepto main else do main
		
		




