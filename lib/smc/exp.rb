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
end

class String
  def to_exp
    JSON.generate(self, quirks_mode: true)
  end
end

class NilClass
  def to_exp
    ":nil"
  end
end
