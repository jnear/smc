require 'json'

class Exp
  def initialize(type, *args)
    @type = type
    @args = args
  end

  def to_exp
    "Exp.new(" + ([@type] + @args).map{|x| x.to_exp}.join(", ") + ")"
  end
  alias :to_s :to_exp

  def to_alloy
    case @args.length
    when 0
      @type.to_s
    when 1
      @args[0].to_s
    when 2
      a, b = @args
      a.to_alloy + "." + b.to_alloy
    else
      a, b, c = @args.take(3)
      if ["+","-", "implies", "==", "and", "or"].include? b then
        #puts @args.map{|x| x.to_s + ": " + x.class.to_s + " = " + x.to_alloy.to_s}.join(", ")
        a.to_alloy + " " + 
          b.to_alloy + " " + 
          c.to_alloy
      else
        a.to_alloy + "." + b.to_alloy + "[" + 
          @args.drop(3).map{|x| x.to_alloy}.join(", ") + "]"
      end
    end
  end
end

class Object
  def to_exp
    JSON.generate(self.to_s, quirks_mode: true)
  end
end

class Symbol
  def to_exp
    JSON.generate(self.to_s, quirks_mode: true)
  end
  #alias :to_alloy :to_exp
end

class String
  def to_exp
    JSON.generate(self, quirks_mode: true)
  end
  alias :to_alloy :to_s
end

class NilClass
  def to_exp
    ":nil"
  end
  #alias :to_alloy :to_exp
end
