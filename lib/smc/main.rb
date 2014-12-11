require File.expand_path(File.dirname(__FILE__) + '/exp')

Exposure = Struct.new(:path, :constraints, :controller, :action) do
  def to_s
    cs = "[" + constraints.join(", ") + "]"
    "Exposure.new(" + [path, cs, controller.to_exp, action.to_exp].join(", ") + ")"
  end
end

require '/home/ubuntu/derailer/lib/derailer/viz/exposures.rb'

puts $read_exposures
