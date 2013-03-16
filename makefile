nodekit_linux = node-webkit-v0.4.2-linux-ia32
nodekit_linux_bin = $(nodekit_linux)/nw
r3_linux = r3-g6a79a7b

#r3 works on wine, node-stuff not
r3_windows = r3-g6a79a7b.exe
nodekit_windows = node-webkit-v0.4.2-win-ia32
nodekit_windows_bin = node-webkit-v0.4.2-win-ia32/nw.exe

#all: coffee run-bu
all: coffee run-nk
#all: run-r3

#run-r3: $(r3_linux)
run-r3: make-rebol $(r3_linux)
	./r3-child -q
#	chmod +x ./$(r3_linux) && ./$(r3_linux) -q
#	./r3 -cs scrapbook.r3

make-rebol: r3-source r3-source
	cp -a $(r3_linux) r3-source/make/r3-make
	make -C r3-source/make prep
	make -C r3-source/make
	cp -a rebol-source/make/r3 r3-child
	
r3-source:
	git clone https://github.com/rebol/r3.git r3-source

gitpull:
	git pull
	cd nw-sample-apps && git pull

run-bu: build
	#$(nodekit_linux_bin) build-dir/werecon.nw
	#build-dir/werecon/werecon
	build-dir/untar/werecon/werecon

	
run-r3-wine: $(r3_windows) r3.exe
	wine r3 -cs scrapbook.r3

run-nk: coffee dl-linux
	$(nodekit_linux_bin) .
	pgrep r3; true #terminate-check
	
run-no: coffee
	node coffee/main.js
	
run-nos: coffee
	node coffee/scrapbook.js

coffee: coffee/main.js coffee/scrapbook.js

coffee/%.js: %.coffee
	coffee -c -o coffee/ $<
	
dl-all: ace.js
	
dl-linux: $(nodekit_linux_bin) $(r3_linux) dl-all
	
$(nodekit_linux_bin):
	wget -c https://s3.amazonaws.com/node-webkit/v0.4.2/node-webkit-v0.4.2-linux-ia32.tar.gz
	tar -xzf $(nodekit_linux).tar.gz
	ls -l $(nodekit_linux_bin)

$(r3_linux):
	wget -c http://www.rebolsource.net/downloads/linux-x86/r3-g6a79a7b
	chmod +x $(r3_linux)
	rm r3
	ln -s $(r3_linux) r3
	
ace.js:
	wget -c http://d1n0x3qji82z53.cloudfront.net/src-min-noconflict/ace.js

build: coffee
	rm build-dir/ -rf
	mkdir -p build-dir/nw
	cp -a *.r3 *.coffee coffee/ *.html *.json *.js makefile $(r3_linux) build-dir/nw
	rm  -f build-dir/nw/local-*
	cp -a $(r3_linux) build-dir/nw/r3 #./r3 is link
	cd build-dir/nw && zip -r ../werecon.nw *
	#bin
	mkdir -p build-dir/werecon
	cat $(nodekit_linux_bin) build-dir/werecon.nw >build-dir/werecon/werecon
	chmod +x build-dir/werecon/werecon
	cp -a $(nodekit_linux)/nw.pak build-dir/werecon
	cd build-dir && tar -czf werecon.tgz werecon
	mkdir -p build-dir/untar
	cd build-dir/untar && tar -xzf ../werecon.tgz
	cp -au build-dir/untar/werecon .
	
	
#######################################	
# nodekit-childprocess does not work on wine, raw node crashes.
# could not test
#######################################

run-nk-w: coffee dl-windows
	$(nodekit_windows_bin) .
	
dl-windows: $(nodekit_windows_bin) $(r3_windows) r3.exe dl-all
	
r3.exe:
	wget -c http://www.rebolsource.net/downloads/win32-x86/r3-g6a79a7b.exe
	cp -a $(r3_windows) r3.exe
	
$(nodekit_windows_bin): r3.exe
	wget -c https://s3.amazonaws.com/node-webkit/v0.4.2/node-webkit-v0.4.2-win-ia32.zip
	unzip node-webkit-v0.4.2-win-ia32.zip



