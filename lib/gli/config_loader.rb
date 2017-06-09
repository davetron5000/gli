require 'yaml'

module GLI
  class ConfigLoader
    def self.load(path)
      File.open(path) { |file| apply_indifferent_access_to(YAML::load(file)) }
    end

    # adapted from https://gist.github.com/Integralist/9503099
    def self.apply_indifferent_access_to(obj)
      return obj.reduce({}) do |memo, (k, v)|
        memo.tap do |m|
          m[k.to_sym] = apply_indifferent_access_to(v)
          m[k] = apply_indifferent_access_to(v)
        end
      end if obj.is_a? Hash

      return obj.reduce([]) do |memo, v|
        memo << apply_indifferent_access_to(v); memo
      end if obj.is_a? Array

      obj
    end
  end
end
