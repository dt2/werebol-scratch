rebol[]

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

mold-were: funct [b] [
	out: copy "["
	unless block? b [b: reduce[b] single: true]
	unless parse b rule: [
		any[
			p: [
				object! (
					append out "{^"object^":{"
					foreach [w v] body-of p/1 [
						repend out [{"} to-word w {":} mold-were v {,}]
					]
					remove back tail out
					append out "}}"
				)
				| number! (append out p/1)
				| string! (repend out [{"} p/1 {"}])
				
			]
			(append out ",")
		]
	][
		;probe system/catalog/errors/script
		cause-error 'script 'invalid-arg reduce[p]
	]
	remove back tail out
	either single[next out][append out "]"]


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
						args: [1]

						res: mold-were context[
							r: args/1 + 1 
							c: context[i: args/1]
							b: reduce[r args/1 "Jo"]
						]
						send "incremented" res
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

