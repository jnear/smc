require 'fnruby'

# data { SimpleAST = String(str) | Id(e) | Ref(obj, field) | BinOp(a, op, b) | Invoke(obj, meth, args) }

data { AlloyAST = AId(str) | Not(a) | AlloyOp(a, op, b) | Join(a, b) | RJoin(a, args) }

def simp_id(id)
  #puts "checking id " + id.to_s
  klasses = $data_model.map{|klass, fields| klass}
  fields = $data_model.flat_map{|klass, fields| fields.map{|field, type| field}}


  ops = ["==", "+", "-", "and", "or", "not"]
  special_ids = ["current_user", "a_string"] + ops
  regexps = [/find_by_(.+)/, /current_user_(.+)/]

  if klasses.include? id or special_ids.include? id or fields.include? id then
    AId(id)
  elsif r = /find_by_(.+)/.match(id) then
    # need to do some twiddling here, I think
    AlloyOp(AId("univ"), AId("->"), AId("~" + r[1]))
  elsif r = /current_user_(.+)/.match(id) then
    # we don't need ids
    AId("current_user")
  else
    raise("fail: simp_id {" + id.to_s + "}")
  end
end

def ok_field(id)
  #puts "checking field " + id.to_s
  fields = $data_model.flat_map{|klass, fields| fields.map{|field, type| field}}
  r = match { with id,
    AId(i) => (fields.include? i)
  }

  puts "checking field " + id.to_s + ": " + r.to_s
  r
end

def mk_id(str)
  match { with str,
    String(str) => mk_id(str),
    Id(str) => mk_id(str),
    str => AId(str)
  }
end

def process(ast)
#  puts ast
  r = match { with ast,
    String(str) => mk_id(str),
    Id(str) => mk_id(str),
    Ref(obj, field) => Join(process(obj), process(field)),
    BinOp(a, op, b) => AlloyOp(process(a), process(op), process(b)),
    Invoke(obj, meth, args) | (args.is_a? Array) => RJoin(Join(process(obj), process(meth)), args.map{|x| process(x)}),
    Invoke(obj, meth, args) => RJoin(Join(process(obj), process(meth)), process(args)),
    str => raise("fail: process {" + str.to_s + "}")
  }

  r

end

def recurse(p, ast)
  match { with ast,
    AId(str) => str,
    Not(a) => Not(p.call(a)),
    AlloyOp(a, op, b) => AlloyOp(p.call(a),
                                 p.call(op),
                                 p.call(b)),
    Join(a, b) => Join(p.call(a),
                       p.call(b)),
    RJoin(a, args) => RJoin(p.call(a),
                            args.map{|x| p.call(x)})
  }
end



# AlloyAST = AId(str) | Not(a) | AlloyOp(a, op, b) | Join(a, b) | RJoin(a, args) }
def simp(ast)
  r = match { with ast,
    AId(str) | (str.is_a? String) => simp_id(str),
    els => recurse(method(:simp), els)
  }
  r
end

def alstr(ast)
  match { with ast,
    AId(str) => str,
    Not(a) => "(not #{alstr(a)})",
    AlloyOp(a, op, b) => "(#{alstr(a)} #{alstr(op)} #{alstr(b)})",
    Join(a, b) => "(#{alstr(a)}.#{alstr(b)})",
    RJoin(a, args) => "(#{alstr(a)}[#{args.map{|a| alstr(a)}.join(", ")}])"
  }
end
