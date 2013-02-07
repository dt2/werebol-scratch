all: coffee/main.js coffee/scrapbook.js run-no

run-nk:
	./nodekit.sh
run-br:
	chromium-browser index.html
run-no:
	node coffee/main.js
run-r3:
	./r3 -cs scrapbook.r3
run-nos:
	node coffee/scrapbook.js


coffee/%.js: %.coffee
	coffee -c -o coffee/ $< 

