rebol[]

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
