require File.expand_path(File.dirname(__FILE__) + '/exp')

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

def mk_one_op(exposure)
  exposure.path.to_alloy
end

def mk_op_sigs
  $read_exposures.map{|x| mk_one_op(x)}.join("\n")
end



puts mk_data_model_sigs

puts mk_op_sigs
