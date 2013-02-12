all: coffee/main.js coffee/scrapbook.js run-nk

run-nk:
	#echo $(pkill -9 r3 && pgrep r3)
	./nodekit.sh
	echo $(pgrep r3)
	
run-cr:
	chromium-browser index.html
run-no:
	node coffee/main.js
run-r3:
	./r3 -cs scrapbook.r3
run-nos:
	node coffee/scrapbook.js


coffee/%.js: %.coffee
	coffee -c -o coffee/ $< 

