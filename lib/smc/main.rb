require 'pry'
require File.expand_path(File.dirname(__FILE__) + '/exp')
require File.expand_path(File.dirname(__FILE__) + '/transform_ast')

Exposure = Struct.new(:path, :constraints, :controller, :action) do
  def to_s
    cs = "[" + constraints.join(", ") + "]"
    "Exposure.new(" + [path, cs, controller.to_exp, action.to_exp].join(", ") + ")"
  end
end

require '/home/ubuntu/derailer/lib/derailer/viz/exposures.rb'

# puts $read_exposures
# puts $data_model

$used_fields = []

def mk_data_model_sigs
  alloy_sigs = $data_model.map{|klass, fields|
    "sig " + klass + " extends Object {\n" +
    fields.select{|field, type| $used_fields.include? field}.
    map{|field, type| "  " + field + ": " + type}.join(",\n") +
    "\n}\n"}.join("\n")
  alloy_sigs
end


PUTS_LOG = false
def log(str)
  if PUTS_LOG then
    puts str
  end
end

def exp_to_ast(exp)
  begin
    exp.to_simpleAst
  rescue => msg
    log "error converting " + exposure.to_s + ": " + msg.to_s
  end
end

def mk_op_sigs(to_process)
#  $read_exposures.map{|x| mk_one_op(x)}.select{|x| filter_op(x)}.join("\n")
  #to_process = $read_exposures

  asts = to_process.map{|x| 
    [exp_to_ast(x.path)] + x.constraints.map{|c| exp_to_ast(c)}
  }

  prep_passes = [:convert_to_alloy,
                 :simplify_ids]

  fml_passes = prep_passes + [:fix_current_user, :alloy_to_string]
  expr_passes = prep_passes + [:alloy_to_string]

  def run_passes(ast, passes)
    cur_ast = ast
    begin
      passes.inject(ast) {|ast, next_pass| cur_ast = ast; method(next_pass).call(ast)}
    rescue => msg
      log "error: " + msg.to_s# + "\n    (#{cur_ast.to_s})"
      nil
    end 
  end

  alloy = asts.map{|xs| 
    first, *rest = xs

    fst = run_passes(first, expr_passes)
    if filter_results(fst) then
      [fst] +
        rest.map{|x| run_passes(x, fml_passes)}.select{|x| filter_results(x)}.uniq
    else
      []
    end
  }.select{|x| x != []}.uniq

  alloy
end

def mk_policy(typ, xs)
  xs.each_with_index.map do |s, i|
    first, *rest = s
    " all r: #{typ}#{i} {\n" + 
      "   r.target in #{first}\n" +
      "   " + rest.join(" and ") +
      "\n }\n"
  end.join("\n")
end

#puts "updates: #{$update_exposures}"



reads = mk_op_sigs($read_exposures)
updates = mk_op_sigs($update_exposures)

op_sigs = reads.each_with_index.map do |s, i|
  "sig Read#{i} extends Read {}"
end.join("\n") + "\n"
  updates.each_with_index.map do |s, i|
  "sig Update#{i} extends Update {}"
end.join("\n")


policy = "pred policy {\n" +
  mk_policy("Read", reads) + "\n\n" +
  mk_policy("Update", updates) +
  "\n}\n"

puts mk_data_model_sigs + "\n"

puts op_sigs + "\n\n"
puts policy + "\n\n"



#puts "USED FIELDS #{$used_fields}"

# puts "WRITES:"

# mk_op_sigs($write_exposures).each do |s|
#   puts "[" + s.join(", ") + "]\n"
# end
