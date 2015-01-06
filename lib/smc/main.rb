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

def mk_data_model_sigs
  alloy_sigs = $data_model.map{|klass, fields|
    "sig " + klass + " extends Object {\n" +
    fields.map{|field, type| "  " + field + ": " + type}.join(",\n") +
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



puts mk_data_model_sigs

reads = mk_op_sigs($read_exposures)

reads.each_with_index do |s, i|
  puts "sig Read#{i} extends Read {}"
end

puts " "
puts "pred policy {"

reads.each_with_index do |s, i|
  first, *rest = s
  puts " all r: Read#{i} {\n" + 
    "   r.target in #{first}\n" +
    "   " + rest.join(" and ") +
    "\n }\n"
end

puts "}\n"


# puts "WRITES:"

# mk_op_sigs($write_exposures).each do |s|
#   puts "[" + s.join(", ") + "]\n"
# end
