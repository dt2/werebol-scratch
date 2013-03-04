werebol-scratch
===============

Werebol - part human, part javascript (rebol, node, webkit)
-----------------------------------------------------------------------------------

Use with https://github.com/rogerwang/node-webkit , see nodekit.sh to run. rebol-binary included.
Testet on Ubuntu 12.04

Latest feature:
--------------------

* console
* one rebol controls the other thru node. but that is hidden :)

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
