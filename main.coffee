inBrowser = typeof window != "undefined"
haveNode = typeof process != "undefined"
haveNodekit = inBrowser && haveNode

if not inBrowser && 1 # testmacromatic
	bye = () ->
		quitR3()
	setTimeout bye, 1000
	
if haveNode
	spawn = require('child_process').spawn

if haveNodekit
	console.error "IGNORE rendersandbox when in nodekit, not implemented"
	gui = require 'nw.gui'
	win = gui.Window.get()
	quitR3 = null
	win.on 'close', () ->
		quitR3()
		this.close true
		
dir = null

child = null

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
	
	switch process.platform
		when "linux"
			dir = if haveNodekit then "#{process.cwd()}/coffee" else __dirname
			d = "#{dir}/.."		
			ls = spawn "#{d}/r3", ["-cs","#{d}/partner.r3"], {stdio: 'pipe'}
		when "win32"
			#pipe does not work on wine
			dir = if haveNodekit then "#{process.cwd()}\\coffee" else __dirname
			d = "#{dir}\\.."		
			ls = spawn "#{d}\\r3.exe", ["-cs","#{d}\\partner.r3"], {stdio: 'pipe'}

	plog "@#{process.platform} dir #{dir} exe #{process.execPath}"

	log "spawning"	

	send "init"
	
	process.nextTick task "listen", () ->
		
		buf = ""
		
		quitR3 = callout () ->
			send "quit"
			ls.stdin.end()
			plog()
			
		ls.stdout.on "data", callout (data) ->
			#log "stdout: " + data
			buf += data
			#log "buf: #{buf}"
			while m = buf.match /(.*?)\n([^]*)/m
				line = m[1]
				buf = m[2]
				#log "got #{m[1]} --- #{m[2]}"
				if line.match /^\*\* /
					log "r3error: #{line}#{buf}"
					clearTimeout nextTick
					#process.exit()
				else if line.match /^~ /
					plog "< #{line}"
					if a = line.match /^~ (\S*) (.*)/
						cmd = a[1]
						args = a[2]
						args = JSON.parse args if args
						handle cmd, args
					else 
						a = line.match /^~ (.*)/
						cmd = a[1]
						handle cmd
				else
					r3log line
			plog()		

		ls.stderr.on "data", callout (data) ->
		  plog "stderr: " + data

		ls.on "exit", callout (code) ->
		  plog "child done res: " + code

	plog "done"
	
send = (s, v) ->
	if v
		v = JSON.stringify v
		#log "-> #{s} #{v}"
		ls.stdin.write "#{s} #{v}\n"
	else
		#log "-> #{s}"
		ls.stdin.write "#{s}\n"
	
plog = (o) ->
	if o != undefined then log o
	return if g.log.length == 1 && g.log[0] == "..."
	d = new Date()
	header = "task: #{g.id}, #{g.name} @#{d}"
	console.log header
	console.log g.log
	logBrowser "#{header}\n#{JSON.stringify g.log}\n"
	g.log = ["..."]
	
logBrowser = (s) ->
	if inBrowser
		s = $('<div/>').text(s).html()
		$("#log").append s
		$("#log").prop "scrollTop", $("#log").prop "scrollHeight"

log = (o) ->
	g.log.push o
	o
	
r3log = (o) ->
	o = "r3log: #{o}  @#{new Date()}"
	console.log o
	logBrowser "#{o}\n"

callout = (f, go = g) ->
	f.g = go
	(args...) ->
		if g
			throw new Exception "task runs in task!"
		g = f.g
		try f args... catch e
			header = "task: #{g.id}, #{g.name}"
			console.log "callout failed [#{header}]:"
			console.log e.stack
			log e
			plog()
			g = null
			return
		g = null
		
task = (name,f) ->
	callout f, new G(name)
	
handle = (cmd, args) ->
	#log "#{cmd} -:- #{JSON.stringify args}"
	switch cmd
		when "set-html" then $("##{args[0]}").html args[1]
		when "on-click"
			$("##{args[0]}").on 'click', callout (e) ->
				contents = {}				
				contents[e] = $("##{e}").val() for e in args[2]
				res = [
					[args[0], args[1]],
					o: contents
				]
				send "clicked", res
		when "call"
			[path, args] = args
			child = spawn path, args, {stdio: 'pipe'}
			ls = child
			ls.on "exit", callout (code) ->
				send "call-reply", [{w: "exit"}, code]
				child = null

	plog()

	
#last!
do task ">r3", () ->
	window.r3 = {}
	window.r3.send = callout (cmd, args) ->
		#plog ">r3: #{cmd} #{JSON.stringify args}"
		send cmd, args

if inBrowser 
	Zepto task "main",main
else 
	do task "main",main

		
		




