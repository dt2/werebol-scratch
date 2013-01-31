rebol[]
buf: copy #{}
forever [
	wait system/ports/input
	data: read system/ports/input
	append buf data
	if parse buf [copy line to "^/" skip copy buf to end] [
		line: to string! line
		if "quit" = line [break]
		probe line
	]		
]
quit

