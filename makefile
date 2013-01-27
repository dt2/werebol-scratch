all: coffee/main.js run

run:
	./nodekit.sh


coffee/%.js: %.coffee
	coffee -c -o coffee/ $< 

