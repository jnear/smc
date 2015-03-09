require 'json'
require 'fnruby'

data { SimpleAST = String(str) | Id(e) | Ref(obj, field) | BinOp(a, op, b) | Invoke(obj, meth, args) }

class Exp
  def initialize(type, *args)
    @type = type
    @args = args
  end

  def to_exp
    "Exp.new(" + ([@type] + @args).map{|x| x.to_exp}.join(", ") + ")"
  end
  alias :to_s :to_exp

  def to_simpleAst
    if @type == "String" then
      String "a_string"
    else
      case @args.length
      when 0
        Id @type.to_simpleAst
      when 1
        Id @args[0].to_simpleAst
      when 2
        a, b = @args
        Ref(a.to_simpleAst, b.to_simpleAst)
      else
        a, b, c = @args.take(3)
        if ["+","-", "implies", "==", "and", "or"].include? b then
          #puts @args.map{|x| x.to_s + ": " + x.class.to_s + " = " + x.to_simpleAst.to_s}.join(", ")
          BinOp(a.to_simpleAst, b.to_simpleAst, c.to_simpleAst)
        elsif b == "query" then
          Invoke(a.to_simpleAst, "find", c.to_simpleAst)
        else
          Invoke(a.to_simpleAst, b.to_simpleAst, @args.drop(2).map{|x| x.to_simpleAst})
        end
      end
    end
  end


  def to_alloy
    if @type == "String" then
      "a_string"
    else
      case @args.length
      when 0
        @type.to_alloy
      when 1
        @args[0].to_alloy
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
        elsif b == "query" then
          a.to_alloy + ".find[" + c.to_alloy + "]"
        else
          a.to_alloy + "." + b.to_alloy + "[" + 
            @args.drop(2).map{|x| x.to_alloy}.join(", ") + "]"
        end
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
  alias :to_alloy :to_s
  alias :to_simpleAst :to_s
end

class String
  def to_exp
    JSON.generate(self, quirks_mode: true)
  end

  def to_alloy
    if md = /find_all_by_(.+)_id/.match(self) then
      "find_by_#{md[1]}"
    else
      self
    end
  end

  def to_simpleAst
    if md = /find_all_by_(.+)_id/.match(self) then
      String "find_by_#{md[1]}"
    else
      String self
    end
  end
end

class NilClass
  def to_exp
    ":nil"
  end
  def to_alloy
    "nil"
  end
  def to_simpleAst
    "nil"
  end
end


class Hash
  def to_simpleAst
    String "some_hash"
  end
end
