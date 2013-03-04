rebol[]

recon: funct["inline-console" b][
	unless parse b [ any [p: end | opt '>> copy cmd [to '>> | to end] (
			print [">> " mold/only cmd]
			print ["==" mold/all do cmd]
		)]
	] [
		print ["does not parse, weird: " mold p ]
	]
]


recon[
	"tests"
	>> "tests done"
]
