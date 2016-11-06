# adapted from https://gist.github.com/Integralist/9503099
class Object
  def with_indifferent_access
    return self.reduce({}) do |memo, (k, v)|
      memo.tap do |m|
        m[k.to_sym] = v.with_indifferent_access
        m[k] = v.with_indifferent_access
      end
    end if self.is_a? Hash
    
    return self.reduce([]) do |memo, v| 
      memo << v.with_indifferent_access; memo
    end if self.is_a? Array
    
    self
  end
end
