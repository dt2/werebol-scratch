inBrowser = typeof window != "undefined"
haveNode = typeof process != "undefined"

g_id = 0

newG = () ->
	ng = () ->
		this.log = []
		this.start = new Date()
		this.id = ++ g_id
		this
	#ng.prototype = g
	g = new ng()

g = newG()	

main = () ->
	console.log "main"
	plog "Have #{ if haveNode then "nodejs" else "no nodejs" }"
	
plog = (o) ->
	if o != undefined then log o
	d = new Date()
	console.log "id: #{g.id} @#{d}"
	console.log g.log
	if inBrowser then $("#log").append "#{g.id} @#{d}\n:#{g.log}\n"
	g.log = ["..."]

log = (o) ->
	g.log.push o
	
callout = (f) ->
	go = newG()
	(args...) ->
		g = go
		try f args... catch e
			console.log e.stack
			log e
			plog()
			return
		
	
			
#last!
if inBrowser then Zepto callout main else do callout main
		
		




