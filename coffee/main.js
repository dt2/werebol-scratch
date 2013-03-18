(function() {
  var G, bye, callout, child, dir, editor, fs, g, g_id, gui, handle, haveNode, haveNodekit, inBrowser, log, logBrowser, logIO, ls, main, nextTick, plog, quitR3, r3log, send, spawn, task, win, workdir,
    __slice = Array.prototype.slice;

  logIO = true;

  logIO = false;

  inBrowser = typeof window !== "undefined";

  haveNode = typeof process !== "undefined";

  haveNodekit = inBrowser && haveNode;

  if (!inBrowser && 1) {
    bye = function() {
      return quitR3();
    };
    setTimeout(bye, 1000);
  }

  if (inBrowser) {
    editor = ace.edit("editor");
    editor.getSession().setUseSoftTabs(false);
  }

  if (haveNode) {
    spawn = require('child_process').spawn;
    fs = require('fs');
  }

  if (haveNodekit) {
    console.error("IGNORE rendersandbox when in nodekit, not implemented");
    gui = require('nw.gui');
    win = gui.Window.get();
    document.title = "WereCon";
    win.show();
    quitR3 = null;
    win.on('close', function() {
      quitR3();
      return this.close(true);
    });
  }

  dir = null;

  workdir = null;

  child = null;

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
        workdir = d.match(/tmp/) ? "" + process.execPath + "/.." : d;
        fs.chmodSync("" + d + "/r3", 0755);
        fs.chmodSync("" + d + "/r3-child", 0755);
        ls = spawn("" + d + "/r3", ["-cs", "" + d + "/partner.r3"], {
          detached: true,
          stdio: 'pipe'
        });
        break;
      case "win32":
        dir = haveNodekit ? "" + (process.cwd()) + "\\coffee" : __dirname;
        d = "" + dir + "\\..";
        workdir = d;
        ls = spawn("" + d + "\\r3.exe", ["-cs", "" + d + "\\partner.r3"], {
          stdio: 'pipe'
        });
    }
    plog("@" + process.platform + " dir " + dir);
    plog("exe " + process.execPath);
    plog("work " + workdir);
    if (inBrowser) document.title = "" + document.title + " " + workdir;
    send("init", {
      o: {
        workdir: {
          f: workdir
        },
        datadir: {
          f: "" + dir + "/.."
        }
      }
    });
    return task("listen", function() {
      var buf;
      buf = "";
      quitR3 = callout(function() {
        if (child) {
          child.stdin.end();
          child.kill();
        }
        send("quit");
        return ls.stdin.end();
      });
      ls.stdout.on("data", callout(function(data) {
        var a, args, cmd, line, m, _results;
        buf += data;
        _results = [];
        while (m = buf.match(/(.*?)\n([^]*)/m)) {
          line = m[1];
          buf = m[2];
          if (line.match(/^\*\* /)) {
            r3log("error: " + line + buf);
            _results.push(clearTimeout(nextTick));
          } else if (line.match(/^~ /)) {
            if (a = line.match(/^~ (\S*) (.*)/)) {
              cmd = a[1];
              args = a[2];
              if (args) args = JSON.parse(args);
              _results.push(handle(cmd, args));
            } else {
              a = line.match(/^~ (.*)/);
              cmd = a[1];
              _results.push(handle(cmd));
            }
          } else {
            _results.push(r3log(line));
          }
        }
        return _results;
      }));
      ls.stderr.on("data", callout(function(data) {
        return plog("stderr: " + data);
      }));
      return ls.on("exit", callout(function(code) {
        return plog("child done res: " + code);
      }));
    });
  };

  send = function(s, v) {
    if (v !== void 0) {
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
    g.log = ["..."];
    return o;
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
    console.log("R3: " + o);
    o = "R3: " + o;
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
        plog(e);
        g = null;
        return;
      }
      return g = null;
    };
  };

  task = function(name, f) {
    return process.nextTick(callout(f, new G(name)));
  };

  handle = function(cmd, args) {
    var a, curs, l, path, s, sendEvent, _ref;
    sendEvent = function(e, cmd) {
      var contents, curs, e, res, sel;
      contents = (function() {
        var _i, _len, _ref, _results;
        _ref = args[2];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          e = _ref[_i];
          _results.push([
            {
              s: e.s
            }, e.s !== "editor" ? {
              s: $("#" + e.s).val()
            } : (sel = editor.session.getTextRange(editor.getSelectionRange()), curs = editor.selection.getCursor(), {
              o: {
                content: {
                  s: editor.getValue()
                },
                selection: {
                  s: sel
                },
                cursor: {
                  o: curs
                }
              }
            })
          ]);
        }
        return _results;
      })();
      res = [[args[0], args[1]], contents];
      return send(cmd, res);
    };
    switch (cmd) {
      case "set-html":
        return $("#" + args[0].s).html(args[1].s);
      case "set-val":
        if (args[0].s !== "editor") {
          return $("#" + args[0].s).val(args[1].s);
        } else {
          if (args[1].s) {
            editor.setValue(args[1].s);
            return editor.gotoLine(0, 0, true);
          } else {
            if (args[1].o.content) editor.setValue(args[1].o.content.s);
            if (args[1].o.cursor) {
              curs = args[1].o.cursor.o;
              editor.gotoLine(curs.row + 1, curs.column, true);
            } else {
              editor.gotoLine(0, 0, true);
            }
            return editor.focus();
          }
        }
        break;
      case "focus":
        if (args.s !== "editor") {
          return $("#" + args.s).focus();
        } else {
          return editor.focus();
        }
        break;
      case "append-html":
        s = args[1].s;
        l = $("#" + args[0].s);
        l.append(s);
        return l.prop("scrollTop", l.prop("scrollHeight"));
      case "append-text":
        l = $("#" + args[0].s);
        s = $('<div/>').text(args[1].s).html();
        l.append(s);
        return l.prop("scrollTop", l.prop("scrollHeight"));
      case "on-click":
        return $("#" + args[0].s).on('click', callout(function(e) {
          return sendEvent(e, "clicked");
        }));
      case "on-text":
        return $("#" + args[0].s).on('keyup', callout(function(e) {
          if (e.keyCode === 13) return sendEvent(e, "text");
        }));
      case "call":
        _ref = args, path = _ref[0], args = _ref[1];
        child = spawn(path.s, (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = args.length; _i < _len; _i++) {
            a = args[_i];
            _results.push(a.s);
          }
          return _results;
        })(), {
          detached: true,
          stdio: 'pipe'
        });
        return task("call", function() {
          child.on("exit", callout(function(code) {
            return send("call.exit", code);
          }));
          child.on("close", callout(function(code) {
            return send("call.close", code);
          }));
          child.stdout.on("data", callout(function(data) {
            data = "" + data;
            return send("call.data", {
              s: data
            });
          }));
          return child.stderr.on("data", callout(function(data) {
            data = "" + data;
            return send("call.error", {
              s: data
            });
          }));
        });
      case "call-send":
        return child.stdin.write("" + args.s + "\n");
      case "call-kill":
        return child.kill();
      case "editor-set":
        return editor.setValue(args.s);
      default:
        send("error", [
          "unknown", {
            s: cmd
          }
        ]);
        return plog("Error: unknown " + cmd);
    }
  };

  task("main", function() {
    if (inBrowser) {
      Zepto(main);
    } else {
      main();
    }
    return task(">r3", function() {
      window.r3 = {};
      return window.r3.send = callout(function(cmd, args) {
        return send(cmd, args);
      });
    });
  });

}).call(this);
