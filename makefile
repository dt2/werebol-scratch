nodekit_linux = node-webkit-v0.4.2-linux-ia32
nodekit_linux_bin = $(nodekit_linux)/nw
r3_linux = r3-g6a79a7b


all: coffee run-nk
#all: run-r3

run-r3: $(r3_linux)
	./r3 -cs scrapbook.r3

run-nk: $(nodekit_linux_bin)
	#ls -l $(nodekit_linux)
	$(nodekit_linux_bin) .
	pgrep r3; true #terminate-check
	
run-cr:
	chromium-browser index.html
run-no:
	node coffee/main.js
run-nos:
	node coffee/scrapbook.js

coffee: coffee/main.js coffee/scrapbook.js

coffee/%.js: %.coffee
	coffee -c -o coffee/ $< 
	
$(nodekit_linux_bin):
	wget -c https://s3.amazonaws.com/node-webkit/v0.4.2/node-webkit-v0.4.2-linux-ia32.tar.gz
	tar -xzf $(nodekit_linux).tar.gz
	ls -l $(nodekit_linux_bin)

$(r3_linux):
	wget -c http://www.rebolsource.net/downloads/linux-x86/r3-g6a79a7b
	chmod +x $(r3_linux)
	rm r3
	ln -s $(r3_linux) r3
