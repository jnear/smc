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

def log(str)
#nothing yet
end

def mk_one_op(exposure)
  begin
    exposure.path.to_simpleAst
  rescue => msg
    log "error converting " + exposure.to_s + ": " + msg.to_s
  end
end

def filter_op(exp)
#  puts exp
  case exp
  when "a_string", "_csrf_token", "nil"
    false
  else
    true
  end
end

def mk_op_sigs
#  $read_exposures.map{|x| mk_one_op(x)}.select{|x| filter_op(x)}.join("\n")
  to_process = $read_exposures.take(20)

  asts = to_process.map{|x| mk_one_op(x)}

  asts.map{|x| 
    begin
      simp(process(x))
    rescue => msg
      "error: " + msg.to_s
    end
  }.join("\n")
end



puts mk_data_model_sigs

puts mk_op_sigs
