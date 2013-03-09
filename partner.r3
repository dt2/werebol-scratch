rebol[]

log-io: true
;log-io: false

buf: copy #{}

unset 'crash
error: funct["hack. use to show error, then crash to mark source" msg][
	print "** ERROR BECAUSE" 
	print remold/all msg
]

send1: funct ['cmd /args s][
	if log-io [print remold/only ['sending cmd s]]
	either args [
		print ["~" cmd bite s]
	][
		print ["~" cmd]
	]
]
send: funct ['cmd s][
	send1/args :cmd s
]

call-child: funct[] [
	;f: %local-child-init.r3
	f: to-file join global/env/workdir %/local-child-init.r3
	
	; while debuging default only !!! 
	; if exists? f [ delete f  ] 
	
	if not exists? f [
		write f mold/only compose/deep [
			rebol[
				title: "Init debug console"
				git: "do not include"
				purpose: "users place to prepare console"
				file: (f)
			]
			reduce [system/script/header/file "loaded"]
		]
	]
	send call [ "./r3" ["--quiet"] ]
	cmd: replace/all trim mold/only compose[
		change-dir (global/env/workdir)
		env: (global/env) 
		do (f)
	] newline " "
	send append-html reduce ["child-log" ajoin[<i> esc cmd </i> newline] ]
	send call-send child/last-input: cmd
]

bite: funct [b] [
	out: copy ""
	if no-block: not block? b [b: reduce[b]]
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
				| word! (repend out [{"} encode-jstring to-string p/1 {"}])
				| string! (repend out ["{^"s^":^"" encode-jstring p/1 "^"}"])
				| block! (append out bite p/1)	
			]
			(append out ",")
		]
		(remove back tail out)
	][
		error ["biting of " type? p/1 "not yet implemented at" p] crash
	]
	either no-block [out][ajoin ["[" out "]"]]
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
	parse v: reduce[v] rule: [ any[ p:
		number! 
		| string! (p/1: load p/1)
		| map! (p/1: chew-map p/1)
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
		| 's set _body string! (val: _body)
		| 'f set _body string! (val: to-file _body)
	][val][error ["unimplemented type" m] crash]
]


main-loop: funct[][
	forever [
		wait system/ports/input
		data: read system/ports/input
		append buf data
		while [parse buf [copy line to "^/" skip copy buf to end]] [
			line: to string! line
			if log-io [print remold/only ['received line]]
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

global: object [env:]

do-cmd: funct[cmd args line][
	cmd: load cmd
	switch/default cmd [
		quit [print "r3 quitting" quit]
		echo [print ["echoing" mold args] print [mold chew args]]
		init [
			global/env: args
			?? global
			/do [recon[
			] exit ]
			send set-html reduce ["rebspace" trim {
				<div style="height: 100%; position: relative;">
				<div 
					style="height: 80%; padding-bottom: 3em; border: solid #00ff00;"
				>
				<pre id="child-log" 
					style="height: 95%; overflow: auto;"
				>
				</pre>
				</div>
				<div style="width: 100%; height: 2em; bottom: 0; position: absolute; border: solid #0000ff;">
				<b>&gt;&gt;</b>
				<input type="text" id="reb-input" 
					value="to-string read %local-child-init.r3"
					style="width: 80%;">
				<button id="do">Do</button>
				<button id="restart">Restart</button>
				</div>
				</div>
			}]
			send on-click reduce["do" 'do ["reb-input"]]
			send on-text reduce["reb-input" 'do ["reb-input"]]
			send on-click reduce["restart" 'restart []]
			
			;send call [ "./r3" ["-cs" "scrapbook.r3"] ]
			call-child
			;send call-send child/last-input: mold/only [do %scrapbook.r3]
			;send call-send mold 'quit
			
			send focus "reb-input"

		]
		clicked text [
			switch/default args/1/2 [
				do [
					do-child args
				]
				edit [
					send set-val reduce["reb-input" args/2/1/2]
					send focus "reb-input"
				]
				restart [
					send1 call-kill
					call-child
				]
			][
				print "unhandled click/text " ?? args
			]
		]
		call.exit [
			print bite reduce [cmd args]
		]
		call.close [
			print bite reduce [cmd args]
		]
		call.data [
			print-child cmd args
		]
		call.error [
			print bite reduce [cmd args]
		]
	][
		print ["unknown-cmd:" line]
	]
]

child: object [
	cmd-cnt: 1
	last-input: 
]

do-child: funct[args][
	id: ++ (in child 'cmd-cnt)
	line: args/2/1/2
	send append-html reduce ["child-log" reword trim {
		<input type="text" id="txt-$id" 
			value="$val"
			style="width: 80%;"><button id="btn-$id">Do</button>
		} reduce [
			'id id 'val esc line
		]
	]
	send on-click reduce [join "btn-" id 'do reduce[join "txt-" id]]
	send on-text reduce [join "txt-" id 'do reduce[join "txt-" id]]
	send on-click reduce [join "txt-" id 'edit reduce[join "txt-" id]]
	
	send call-send child/last-input: line
	either "reb-input" = args/2/1/1 [
		;send set-val ["reb-input" ""]
	][
		send set-val reduce["reb-input" line]
	]
	;send focus join "txt-" id
	send focus "reb-input"
]

print-child: funct[cmd args][
	s: copy ""
	if child/last-input [
		append s ajoin [">> " child/last-input newline]
		child/last-input: none
	]
	append s reduce [args]
	send append-text reduce ["child-log" join args ""]
	;print bite s	
]

esc: func[s][
	parse s: copy s [any[
		change "<" "&lt;" | change ">" "&gt;" | change "&" "&amp;" | change {"} "&quot;"
		| skip]]
	s
]

recon: funct["inline-console" b][
	unless parse b [ any [p: end | opt '>> copy cmd [to '>> | to end] (
			print [">> " mold/only cmd]
			print ["==" mold/all do cmd]
		)]
	] [
		print ["does not parse, weird: " mold p ]
	]
]



main-loop

