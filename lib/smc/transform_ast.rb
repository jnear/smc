require 'fnruby'

# data { SimpleAST = String(str) | Id(e) | Ref(obj, field) | BinOp(a, op, b) | Invoke(obj, meth, args) }

data { AlloyAST = AId(str) | Not(a) | AlloyOp(a, op, b) | Join(a, b) | RJoin(a, args) }

def ok_id(id)
#  puts "checking id " + id.to_s
  klasses = $data_model.map{|klass, fields| klass}
  match { with id,
    AId(i) => (klasses.include? i or ["current_user"].include? i)
  }
end

def ok_field(id)
#  puts "checking field " + id.to_s
  fields = $data_model.flat_map{|klass, fields| fields.map{|field, type| field}}
  match { with id,
    AId(i) => (fields.include? i)
  }
end

def process(ast)
#  puts ast
  r = match { with ast,
    String(str) => AId(str),
    Id(String(str)) => AId(str),
    Id(str) => AId(str),
    Ref(obj, field) | (ok_id process(obj) and ok_field process(field)) => Join(process(obj), process(field)),
    BinOp(a, op, b) => AlloyOp(process(a), process(op), process(b)),
    Invoke(obj, meth, args) | (args.is_a? Array) => RJoin(Join(process(obj), process(meth)), args.map{|x| process(x)}),
    Invoke(obj, meth, args) => RJoin(Join(process(obj), process(meth)), process(args)),
    str => AId("fail:" + str.to_s)
  }

  if r then
    r
  else
    "failed to match " + ast.to_s
  end
end
