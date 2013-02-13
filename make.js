console.log(__dirname);
var spawn = require('child_process').spawn;
var d = "#{__dirname}/.."
console.log( "making"	);
var ls = spawn( "make", ["coffee"], { stdio: 'inherit', cwd: __dirname });
ls.on('exit', function (code) {
  console.log('make res: ' + code);
});
require("./coffee/main.js");

