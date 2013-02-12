rebol[]

buf: copy #{}

unset 'crash
error: funct["hack. use to show error, then crash to mark source" msg][
	print "** ERROR BECAUSE" 
	print remold/all msg
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

bite: funct [b] [
	out: copy "["
	unless block? b [b: reduce[b] single: true]
	unless parse b rule: [
		any[
			p: [
				object! (
					append out "{^"o^":{"
					foreach [w v] body-of p/1 [
						repend out [{"} to-word w {":} bite v {,}]
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
		error ["biting not yet implemented at" p] crash
	]
	remove back tail out
	either single[next out][append out "]"]
]

load-node: funct [s /local _n _s _key _map] [
	innumber: charset "0123456789.e"
	number: [copy _n some innumber (append out load _n)]
	instring: complement charset {"\}
	string: [ {"} copy _s any [ instring | "\" skip] {"} (append out _s)]
	val: [
		p: 
		number
		| string
		| array
		| _map
	]
	array: [
		"[" (insert/only stack out   out: copy []) 
		any [opt "," val]
		"]" (parent: take stack   append/only parent out   out: parent)
	]
	_map: [
		"{" (insert/only stack out   out: copy [])
		any[ opt "," {"} copy _key to {":} {":} (append out to-word _key) val]
		"}" (parent: take stack   append/only parent map out   out: parent)
	]
	out: copy[]
	stack: copy[]
	if parse s val [out/1]
]

chew: funct [s /local] [
	chew-val load-node s
]

chew-val: funct [v] [
	parse v: reduce[v] rule: [ any[
		number! | string! | into rule
		| p: map! (p/1: chew-map p/1)
	]]
	v/1
]

chew-map: funct [m /local _body][
	either parse body-of m [
		'o set _body skip (
			out: copy[]
			foreach [key val] body-of _body [ repend out [to-set-word key chew-val val] ]
		)
	][construct out][error ["untyped map" m] 1 / 0]
]


main-loop: funct[][
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
				do-cmd cmd
			][
				send "unknown-format" mold line
			]
		]		
	]
]

do-cmd: funct[cmd][
	switch/default cmd [
		"quit" [print "r3 quitting" quit]
		"echo" [print ["echoing" mold args] print [mold chew args]]
		"init" [print "r3 starting"]
	][
		send "unknown-cmd" mold line
	]
]

recon: funct["inline-console" b][
	unless parse b [ any [p: '& copy cmd [to '& | to end] (
			print [">> " mold cmd]
			print ["==" mold/all do cmd]
		)]
	] [
		print [mold p "'& missing?" ]
	]
]

recon[
	& source print
]

main-loop

