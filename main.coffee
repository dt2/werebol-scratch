logIO = true
logIO = false

inBrowser = typeof window != "undefined"
haveNode = typeof process != "undefined"
haveNodekit = inBrowser && haveNode

if not inBrowser && 1 # testmacromatic
	bye = () ->
		quitR3()
	setTimeout bye, 1000
	
if inBrowser
	editor = ace.edit("editor");
	
if haveNode
	spawn = require('child_process').spawn
	fs = require 'fs'

if haveNodekit
	console.error "IGNORE rendersandbox when in nodekit, not implemented"
	gui = require 'nw.gui'
	win = gui.Window.get()
	document.title = "WereCon"
	win.show();
	quitR3 = null
	win.on 'close', () ->
		quitR3()
		this.close true

dir = null
workdir = null

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
			workdir = if d.match /tmp/ then "#{process.execPath}/.." else d
			fs.chmodSync "#{d}/r3", 0755
			ls = spawn "#{d}/r3", ["-cs","#{d}/partner.r3"], {stdio: 'pipe'}
		when "win32"
			#pipe does not work on wine
			dir = if haveNodekit then "#{process.cwd()}\\coffee" else __dirname
			d = "#{dir}\\.."
			workdir = d
			ls = spawn "#{d}\\r3.exe", ["-cs","#{d}\\partner.r3"], {stdio: 'pipe'}

	plog "@#{process.platform} dir #{dir}"
	plog "exe #{process.execPath}"
	plog "work #{workdir}"
	if inBrowser
		document.title = "#{document.title} #{workdir}"
	
	send "init", o: {workdir: {f: workdir}, datadir: {f: "#{dir}/.."}}
	
	task "listen", () ->
		
		buf = ""
		
		quitR3 = callout () ->
			if child
				child.stdin.end()
				child.kill()
			send "quit"
			ls.stdin.end()
			
		ls.stdout.on "data", callout (data) ->
			buf += data
			while m = buf.match /(.*?)\n([^]*)/m
				line = m[1]
				buf = m[2]
				if line.match /^\*\* /
					r3log "error: #{line}#{buf}"
					clearTimeout nextTick
					#process.exit()
				else if line.match /^~ /
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

		ls.stderr.on "data", callout (data) ->
		  plog "stderr: " + data

		ls.on "exit", callout (code) ->
		  plog "child done res: " + code


send = (s, v) ->
	if v != undefined
		v = JSON.stringify v
		ls.stdin.write "#{s} #{v}\n"
	else
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
	o
	
logBrowser = (s) ->
	if inBrowser
		s = $('<div/>').text(s).html()
		$("#log").append s
		$("#log").prop "scrollTop", $("#log").prop "scrollHeight"

log = (o) ->
	g.log.push o
	o
	
r3log = (o) ->
	console.log "R3: #{o}"
	o = "R3: #{o}"
	#o = "R3: #{o}  @#{new Date()}"
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
			plog(e)
			g = null
			return
		g = null
		
task = (name,f) ->
	process.nextTick callout f, new G(name)
	
handle = (cmd, args) ->
	#log "#{cmd} -:- #{JSON.stringify args}"
	
	sendEvent =  (e,cmd) -> # cmd from parent
		contents = ([
			{s: e.s}, 
			if e.s != "editor" then {s: $("##{e.s}").val()}
			else
				sel = editor.session.getTextRange editor.getSelectionRange()
				curs = editor.selection.getCursor()
				o: 
					content: s: editor.getValue()
					selection: s: sel
					cursor: o: curs
		] for e in args[2] )
		res = [
			[args[0], args[1]], contents
		]
		send cmd, res	
		
	switch cmd
		when "set-html" then $("##{args[0].s}").html args[1].s
		when "set-val" 
			if args[0].s != "editor" then $("##{args[0].s}").val args[1].s
			else 
				if args[1].s
					editor.setValue args[1].s
					editor.gotoLine 0, 0, true # hack: clears focus
				else 
					if args[1].o.content
						editor.setValue args[1].o.content.s
					if args[1].o.cursor
						plog args
						curs = args[1].o.cursor.o
						editor.gotoLine curs.row + 1, curs.column, true
					else 
						editor.gotoLine 0, 0, true # hack: clears focus
					editor.focus()

		when "focus" 
			if args.s != "editor" then $("##{args.s}").focus()
			else editor.focus()
		when "append-html" 
			s = args[1].s
			l = $ "##{args[0].s}"
			l.append s
			l.prop "scrollTop", l.prop "scrollHeight"
		when "append-text"
			l = $ "##{args[0].s}"
			s = $('<div/>').text(args[1].s).html()
			l.append s
			l.prop "scrollTop", l.prop "scrollHeight"
		when "on-click"
			$("##{args[0].s}").on 'click', callout (e) -> sendEvent e, "clicked"
		when "on-text"
			$("##{args[0].s}").on 'keyup', callout (e) ->
				if e.keyCode == 13
					sendEvent e, "text"
		when "call"
			[path, args] = args
			child = spawn path.s, (a.s for a in args), {stdio: 'pipe'}
			task "call", () ->
				child.on "exit", callout (code) ->
					send "call.exit", code
					#plog "exit"
				child.on "close", callout (code) ->
					send "call.close", code
					#plog "close"
				child.stdout.on "data", callout (data) ->
					data = "" + data
					send "call.data", {s: data}
					#plog "" + data
				child.stderr.on "data", callout (data) ->
					data = "" + data
					send "call.error", {s: data}
					#plog data
		when "call-send"
			child.stdin.write "#{args.s}\n"
		when "call-kill"
			plog args
			child.kill()
			
		when "editor-set" #deprecated, use set-val
			editor.setValue args.s

		else			
			send "error", ["unknown", {s: cmd}]
			plog "Error: unknown #{cmd}"
	
task "main", () ->
	if inBrowser 
		Zepto main
	else 
		do main
	task ">r3", () ->
		window.r3 = {}
		window.r3.send = callout (cmd, args) ->
			#plog ">r3: #{cmd} #{JSON.stringify args}"
			send cmd, args


		
		




