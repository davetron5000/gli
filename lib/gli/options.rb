require 'ostruct'

module GLI
  class Options < OpenStruct

    def[](k)
      @table[k.to_sym]
    end

    def[]=(k, v)
      @table[k.to_sym] = v
    end

  end
end

