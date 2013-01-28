all: coffee/main.js run-nj
#all: coffee/main.js run-nk
#all: coffee/main.js run-br

run-nk:
	./nodekit.sh
run-br:
	chromium-browser index.html
run-nj:
	node coffee/main.js


coffee/%.js: %.coffee
	coffee -c -o coffee/ $< 

