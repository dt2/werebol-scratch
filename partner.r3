rebol[]
do %altjson.r
buf: copy #{}
if "main" = system/script/args [
	print "as main"
	quit
]
send1: funct [cmd /args s][
	either args [
		print ["~" cmd s]
	][
		print ["~" cmd]
	]
]
send: funct [cmd s][
	send1/args cmd s
]

do funct[][
	forever [
		wait system/ports/input
		data: read system/ports/input
		append buf data
		while [parse buf [copy line to "^/" skip copy buf to end]] [
			line: to string! line
			;print ["got" line]
			if parse line [
				[copy cmd to " " skip copy args to end]
				| [copy cmd to end]
			] [
				switch/default cmd [
					"quit" [quit]
					"echo" [send "echoing" line]
					"inc" [
						args: load-json args
						args/1: args/1 + 1
						send "incremented" to-json args
					]
					"init" [send1 "dummy-init"]
				][
					send "unknown-cmd" mold line
				]
			][
				send "unknown-format" mold line
			]
		]		
	]
]

