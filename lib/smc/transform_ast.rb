require 'fnruby'

# data { SimpleAST = String(str) | Id(e) | Ref(obj, field) | BinOp(a, op, b) | Invoke(obj, meth, args) }

data { AlloyAST = AId(str) | Not(a) | AlloyOp(a, op, b) | Join(a, b) | RJoin(a, args) }

def simp_id(id)
  #puts "checking id " + id.to_s
  klasses = $data_model.map{|klass, fields| klass}
  fields = $data_model.flat_map{|klass, fields| fields.map{|field, type| field}}


  ops = ["==", "+", "-", "and", "or", "not"]
  special_ids = ["current_user", "a_string", "new", "update_attributes", "find_by", "some_hash"] + ops
  regexps = [/find_by_(.+)/, /current_user_(.+)/]

  if klasses.include? id or special_ids.include? id then
    AId(id)
  elsif fields.include? id then
    $used_fields << id unless $used_fields.include? id
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


def mk_id(str)
  match { with str,
    String(str) => mk_id(str),
    Id(str) => mk_id(str),
    str | (str.is_a? String) => AId(str),
    els => convert_to_alloy(els)
  }
end

def convert_to_alloy(ast)
#  puts ast
  alias :process :convert_to_alloy
  r = match { with ast,
    String(str) => mk_id(str),
    Id(str) => mk_id(str),
    Ref(obj, field) => Join(process(obj), process(field)),
    BinOp(a, op, b) => AlloyOp(process(a), process(op), process(b)),
    Invoke(obj, meth, args) | (args.is_a? Array) => RJoin(Join(process(obj), process(meth)), args.map{|x| process(x)}),
    Invoke(obj, meth, args) => RJoin(Join(process(obj), process(meth)), process(args)),
    str | (str.is_a? String) => AId(str),
    str => raise("fail: process {" + str.to_s + "}")
  }

  r

end

def recurse(p, ast)
#  puts p, ast
  r = match { with ast,
    AId(str) => AId(str),
    Not(a) => Not(p.call(a)),
    AlloyOp(a, op, b) => AlloyOp(p.call(a),
                                 p.call(op),
                                 p.call(b)),
    Join(a, b) => Join(p.call(a),
                       p.call(b)),
    RJoin(a, args) => RJoin(p.call(a),
                            args.map{|x| p.call(x)})
  }
  if r == false then
    raise "failed recurse (#{p}): #{ast.class}: #{ast}"
  end
  r
end



# AlloyAST = AId(str) | Not(a) | AlloyOp(a, op, b) | Join(a, b) | RJoin(a, args) }
def simplify_ids(ast)
  match { with ast,
    AId(str) | (str.is_a? String) => simp_id(str),
    RJoin(Join(a, AId("find")), b) => simplify_ids(a),
    els => recurse(method(:simplify_ids), els)
  }
end

def fix_current_user(ast)
  match { with ast,
    AId("current_user") => AId("some current_user"),
    els => els
  }
end

def alloy_to_string(ast)
  alias :alstr :alloy_to_string
  match { with ast,
    Join(a, AId("new")) => alstr(a),
    RJoin(Join(a, AId("find_by")), b) => alstr(a), # this one is not quite cool
    Join(a, AId("update_attributes")) => alstr(a),
    AId(str) => str,
    Not(a) => "(not #{alstr(a)})",
    AlloyOp(a, op, b) => "(#{alstr(a)} #{alstr(op)} #{alstr(b)})",
    Join(a, b) => "(#{alstr(a)}.#{alstr(b)})",
    RJoin(a, args) => "(#{alstr(a)}[#{args.map{|a| alstr(a)}.join(", ")}])",
    els => raise("fail: alloy_to_string {" + els.to_s + "}")
  }
end

def filter_results(str)
  if str == "a_string" or str == nil then
    false
  else
    true
  end
end
