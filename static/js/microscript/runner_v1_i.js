this.Runner = (function() {
  function Runner(microvm) {
    this.microvm = microvm;
  }

  Runner.prototype.run = function(program) {
    var context, i, j, len, ref, res, s;
    res = 0;
    context = this.microvm.context;
    ref = program.statements;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      s = ref[i];
      res = s.evaluate(context, i === program.statements.length - 1);
    }
    return res;
  };

  Runner.prototype.call = function(name, args) {
    var a, f, i, j, ref;
    if (name instanceof Program.Function) {
      f = name;
    } else {
      f = this.microvm.context.global[name];
    }
    if (f != null) {
      if (f instanceof Program.Function) {
        for (i = j = 0, ref = args.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
          a = args[i];
          if (typeof a === "number") {
            args[i] = new Program.Value(null, Program.Value.TYPE_NUMBER, a);
          } else if (typeof a === "string") {
            args[i] = new Program.Value(null, Program.Value.TYPE_STRING, a);
          } else {
            args[i] = new Program.Value(null, Program.Value.TYPE_OBJECT, a);
          }
        }
        return new Program.FunctionCall(f.token, f, args).evaluate(this.microvm.context, true);
      } else if (typeof f === "function") {
        return f.apply(null, args);
      }
    } else {
      return 0;
    }
  };

  return Runner;

})();
