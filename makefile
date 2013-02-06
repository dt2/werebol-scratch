all: coffee/main.js run-no

run-nk:
	./nodekit.sh
run-br:
	chromium-browser index.html
run-no:
	node coffee/main.js
run-r3:
	./r3 -cs partner.r3 main


coffee/%.js: %.coffee
	coffee -c -o coffee/ $< 

