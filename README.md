werebol-scratch
===============

Werebol - part human, part javascript (rebol, node, webkit)
-----------------------------------------------------------------------------------

Use with https://github.com/rogerwang/node-webkit , type make to run. rebol-binary included.
Testet on Ubuntu 12.04

Latest feature:
--------------------

* console
* one rebol controls the other thru node. but that is hidden :)

Running demo in vm
-------------------

From inside image: Google for "werebol" (worked here). Back at this readme again. Download https://raw.github.com/dt2/werebol-scratch/master/fresh-vm/makefile . Cd to it, type "make", enter password. It does an apt-get, downloads and runs demo.

I use an image from http://virtualboxes.org/images/ubuntu/ on virtualbox on ubuntu 12.04. 
Active user account(s) (username/password): ubuntu/reverse.
http://sourceforge.net/projects/virtualboximage/files/Ubuntu%20Linux/12.04/ubuntu_12.04-x86.7z

By gui. Unzipped, klicked on *.vbox, ignored a warning about a *.vdi, disabled bluetooth somewhere. A while later the launcher for this image appeared.


make includes downloading and running.
----------------------------------------------------------
Own risk ;)

    make # downloads nodekit, rebol and runs.
    make dl-linux   # downloads only    
    make dl-windows # downloads for wine. unfortunally does not work on wine
    make run-nk-w   # wine-download and runs wrongly

Screenshot
----------------
![Screenshot](http://i.imgur.com/jgXbzCH.png)
