(function() {
  var G, bye, callout, dir, g, g_id, gui, handle, haveNode, haveNodekit, inBrowser, log, logBrowser, ls, main, nextTick, plog, quitR3, r3log, send, spawn, task, win,
    __slice = Array.prototype.slice;

  inBrowser = typeof window !== "undefined";

  haveNode = typeof process !== "undefined";

  haveNodekit = inBrowser && haveNode;

  if (!inBrowser && 1) {
    bye = function() {
      return quitR3();
    };
    setTimeout(bye, 1000);
  }

  if (haveNode) spawn = require('child_process').spawn;

  if (haveNodekit) {
    console.error("IGNORE rendersandbox when in nodekit, not implemented");
    gui = require('nw.gui');
    win = gui.Window.get();
    quitR3 = null;
    win.on('close', function() {
      quitR3();
      return this.close(true);
    });
  }

  dir = null;

  g_id = 0;

  ls = null;

  nextTick = null;

  G = function(name) {
    this.log = [];
    this.start = new Date();
    this.id = ++g_id;
    this.name = name;
    return this;
  };

  g = null;

  main = function() {
    var d;
    switch (process.platform) {
      case "linux":
        dir = haveNodekit ? "" + (process.cwd()) + "/coffee" : __dirname;
        d = "" + dir + "/..";
        ls = spawn("" + d + "/r3", ["-cs", "" + d + "/partner.r3"], {
          stdio: 'pipe'
        });
        break;
      case "win32":
        dir = haveNodekit ? "" + (process.cwd()) + "\\coffee" : __dirname;
        d = "" + dir + "\\..";
        ls = spawn("" + d + "\\r3.exe", ["-cs", "" + d + "\\partner.r3"], {
          stdio: 'pipe'
        });
    }
    plog("@" + process.platform + " dir " + dir + " exe " + process.execPath);
    log("spawning");
    send("init");
    process.nextTick(task("listen", function() {
      var buf;
      buf = "";
      quitR3 = callout(function() {
        send("quit");
        return plog();
      });
      ls.stdout.on("data", callout(function(data) {
        var a, args, cmd, line, m;
        buf += data;
        while (m = buf.match(/(.*?)\n([^]*)/m)) {
          line = m[1];
          buf = m[2];
          if (line.match(/^\*\* /)) {
            log("r3error: " + line + buf);
            clearTimeout(nextTick);
          } else if (line.match(/^~ /)) {
            if (a = line.match(/^~ (\S*) (.*)/)) {
              cmd = a[1];
              args = a[2];
              if (args) args = JSON.parse(args);
              handle(cmd, args);
            } else {
              a = line.match(/^~ (.*)/);
              cmd = a[1];
              handle(cmd);
            }
          } else {
            r3log(line);
          }
        }
        return plog();
      }));
      ls.stderr.on("data", callout(function(data) {
        return plog("stderr: " + data);
      }));
      return ls.on("exit", callout(function(code) {
        return plog("child done res: " + code);
      }));
    }));
    return plog("done");
  };

  send = function(s, v) {
    if (v) {
      v = JSON.stringify(v);
      return ls.stdin.write("" + s + " " + v + "\n");
    } else {
      return ls.stdin.write("" + s + "\n");
    }
  };

  plog = function(o) {
    var d, header;
    if (o !== void 0) log(o);
    if (g.log.length === 1 && g.log[0] === "...") return;
    d = new Date();
    header = "task: " + g.id + ", " + g.name + " @" + d;
    console.log(header);
    console.log(g.log);
    logBrowser("" + header + "\n" + (JSON.stringify(g.log)) + "\n");
    return g.log = ["..."];
  };

  logBrowser = function(s) {
    if (inBrowser) {
      s = $('<div/>').text(s).html();
      $("#log").append(s);
      return $("#log").prop("scrollTop", $("#log").prop("scrollHeight"));
    }
  };

  log = function(o) {
    g.log.push(o);
    return o;
  };

  r3log = function(o) {
    o = "r3log: " + o + "  @" + (new Date());
    console.log(o);
    return logBrowser("" + o + "\n");
  };

  callout = function(f, go) {
    if (go == null) go = g;
    f.g = go;
    return function() {
      var args, header;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (g) throw new Exception("task runs in task!");
      g = f.g;
      try {
        f.apply(null, args);
      } catch (e) {
        header = "task: " + g.id + ", " + g.name;
        console.log("callout failed [" + header + "]:");
        console.log(e.stack);
        log(e);
        plog();
        g = null;
        return;
      }
      return g = null;
    };
  };

  task = function(name, f) {
    return callout(f, new G(name));
  };

  handle = function(cmd, args) {
    switch (cmd) {
      case "set-html":
        $("#" + args[0]).html(args[1]);
        break;
      case "on-click":
        $("#" + args[0]).on('click', callout(function(e) {
          var contents, res, _i, _len, _ref;
          contents = {};
          _ref = args[2];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            e = _ref[_i];
            contents[e] = $("#" + e).val();
          }
          res = [
            [args[0], args[1]], {
              o: contents
            }
          ];
          return send("clicked", res);
        }));
    }
    return plog();
  };

  task(">r3", function() {
    window.r3 = {};
    return window.r3.send = callout(function(cmd, args) {
      return send(cmd, args);
    });
  })();

  if (inBrowser) {
    Zepto(task("main", main));
  } else {
    task("main", main)();
  }

}).call(this);
