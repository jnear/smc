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

def mk_op_sigs
#  $read_exposures.map{|x| mk_one_op(x)}.select{|x| filter_op(x)}.join("\n")
  to_process = $read_exposures

  asts = to_process.map{|x| 
    [exp_to_ast(x.path)] + x.constraints.map{|c| exp_to_ast(c)}
  }

  passes = [:convert_to_alloy,
            :simplify_ids,
            :fix_current_user,
            :alloy_to_string
            ]

  alloy = asts.map{|xs| 
    xs.map{|x|
      cur_ast = x
      begin
        result = passes.inject(x) {|ast, next_pass| cur_ast = ast; method(next_pass).call(ast)}
        if result.to_s.include? "BinOp" then
          binding.pry
        end
        result
      rescue => msg
        log "error: " + msg.to_s# + "\n    (#{cur_ast.to_s})"
        nil
      end 
    }.select{|x| filter_results(x)}.uniq
  }.select{|x| x != []}.uniq

  alloy
end



puts mk_data_model_sigs

mk_op_sigs.each do |s|
  puts "[" + s.join(", ") + "]\n"
end
