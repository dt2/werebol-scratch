inBrowser = typeof window != "undefined"
haveNode = typeof process != "undefined"

if haveNode
	spawn = require('child_process').spawn

g_id = 0
ls = null
nextTick = null

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
	ls = spawn "./r3", ["-cs","partner.r3"], {stdio: 'pipe'}

	send "init"

	n = 0
	process.nextTick ticker = task "ticker", () ->
		++ n
		if n <= 1
			send "inc #{JSON.stringify [n]}"				
			nextTick = setTimeout ticker, 1000
		else
			send "quit"
		plog()
			
	process.nextTick task "listen", () ->
		
		buf = ""
		
		ls.stdout.on "data", callout (data) ->
			#log "stdout: " + data
			buf += data
			#log "buf: #{buf}"
			if buf.match /^\*\* /
				plog "aborting: #{buf}"
				process.exit()
			while m = buf.match /(.*?)\n([^]*)/m
				line = m[1]
				buf = m[2]
				log "got #{m[1]} --- #{m[2]}"
				if line.match /^~ /
					if a = line.match /incremented (.*)/
						log a[1]
						j = JSON.parse(a[1])
						log "json worked"
					else
						log "#{line}"
				else
					log "r3log: #{line}"
			plog()		

		ls.stderr.on "data", callout (data) ->
		  plog "stderr: " + data

		ls.on "exit", callout (code) ->
		  plog "child done res: " + code

	plog "done"
	
send = (s) ->
	log "-> #{s}"
	ls.stdin.write "#{s}\n"
	
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
	o
	
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
		
		




