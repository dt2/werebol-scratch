rebol[]
while [
	wait system/ports/input
	data: to string! read system/ports/input
	data <> "quit^/" 
] [
	probe data
]
print "bye"
quit

