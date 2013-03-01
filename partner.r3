rebol[]

buf: copy #{}

unset 'crash
error: funct["hack. use to show error, then crash to mark source" msg][
	print "** ERROR BECAUSE" 
	print remold/all msg
]

send1: funct ['cmd /args s][
	either args [
		print ["~" cmd bite s]
	][
		print ["~" cmd]
	]
]
send: funct ['cmd s][
	send1/args :cmd s
]

bite: funct [b] [
	out: copy ""
	b: reduce[b]
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
				| string! (repend out [{"} encode-jstring p/1 {"}])
				| word! (repend out ["{^"w^":^"" p/1 "^"}"])
				| and block! (append out "[") into rule (append out "]")
				
			]
			(append out ",")
		]
		(remove back tail out)
	][
		error ["biting of " type? p/1 "not yet implemented at" p] crash
	]
	out
]

; http://www.ietf.org/rfc/rfc4627.txt
; http://www.rebol.com/r3/docs/datatypes/char.html

r2j-chars: copy""
parse {
                  %x22 /          ; "    quotation mark  U+0022
                    %x5C /          ; \    reverse solidus U+005C
                    %x2F /          ; /    solidus         U+002F
                    %x62 /          ; b    backspace       U+0008
                    %x66 /          ; f    form feed       U+000C
                    %x6E /          ; n    line feed       U+000A
                    %x72 /          ; r    carriage return U+000D
                    %x74 /          ; t    tab             U+0009
} [
	any [
		thru "; " copy _esc skip thru "U+" 2 skip copy _asc 2 skip
		(repend r2j-chars [ "{^^(" _asc ")} {\" _esc "} " ])
	]
]
r2j-chars: load r2j-chars

r2j-char: copy[]
foreach [r j] r2j-chars [
	repend r2j-char ['change r j '|]
]
append r2j-char 'skip

j2r-char: copy[]
foreach [r j] r2j-chars [
	repend j2r-char ['change j r '|]
]
append j2r-char 'skip

encode-jstring: funct[s] [
	parse s: copy s [any r2j-char]
	s
]

decode-jstring: func[s] [
	parse s: copy s [any j2r-char]
	s
]

load-node: funct [s /local _n _s _key _map] [
	innumber: charset "0123456789.e-"
	number: [copy _n some innumber (append out load _n)]
	instring: complement charset {"\}
	string: [ {"} copy _s any [ instring | "\" skip] {"} (append out decode-jstring _s)]
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
		any[ opt "," {"} copy _key to {":} {":} 
			(append out to-word  decode-jstring _key) val]
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
		number! | string! 
		| p: map! (p/1: chew-map p/1)
		| and block! into rule
	]]
	v/1
]

chew-map: funct [m /local _body][
	either parse body-of m [
		'o set _body skip (
			out: copy[]
			foreach [key val] body-of _body [ 
			  repend out [to-set-word key chew-val val] ]
			val: construct out
		)
		| 'w set _body string! (val: to-word _body)
	][val][error ["untyped map" m] crash]
]


main-loop: funct[][
	forever [
		wait system/ports/input
		data: read system/ports/input
		append buf data
		while [parse buf [copy line to "^/" skip copy buf to end]] [
			line: to string! line
			;?? line
			cmd: args: none
			if parse line [
				[copy cmd to " " skip copy args to end 
					(args: chew args)]
				| [copy cmd to end]
			] [
				do-cmd cmd args line
			][
				send unknown-format mold line
			]
		]		
	]
]

do-cmd: funct[cmd args line][
	switch/default cmd [
		"quit" [print "r3 quitting" quit]
		"echo" [print ["echoing" mold args] print [mold chew args]]
		"init" [
			print "r3 starting"
			send set-html reduce ["rebspace" ajoin[
				<span id="out">mold now</span><br>
				<input type="text" id="line-1" value="123">
				<br><input type="text" id="line-2" value="234">
				<button id="add">"+"</button>
				<br>"result: "<span id="res">"---"</span>
				<p>{chartest: " \  < }<br>
			]]
			send on-click reduce["add" 'add ["line-1" "line-2"]]
		]
		"clicked" [
			;print "clicked" probe args
			send set-html reduce[ "res"
				mold try[
					add  load args/2/line-1  load args/2/line-2
				]
			]
		]
	][
		send "unknown-cmd" line
	]
]

recon: funct["inline-console" b][
	unless parse b [ any [p: '>> copy cmd [to '>> | to end] (
			print [">> " mold/only cmd]
			print ["==" mold/all do cmd]
		)]
	] [
		print [mold p "'& missing?" ]
	]
]

recon[
	>> "tests"
	>> "tests done"
]

main-loop

