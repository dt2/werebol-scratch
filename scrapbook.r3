rebol[]

recon: funct["inline-console" b][
	cmd: vis: none
	unless parse b [ any [p: end | opt '>> copy cmd [to '>> | to end] (
			hidden: none
			either parse cmd [copy vis to '<< skip copy hidden to end][
				cmd: vis
			][
				
			]
			if not empty? cmd [
				print [">> " mold/only cmd]
				print ["==" mold/all do cmd]
			]
			if hidden [
				print "..."
				do hidden
			]
		)]
	] [
		print ["does not parse, weird: " mold p ]
	]
]


recon[
>> esc: func[s][
	parse s [any[change "<" "&lt;" | change ">" "&gt;" | change "&" "&amp;" | skip]]
	s
]
>> esc a: "123 <>&"
>> a
]
