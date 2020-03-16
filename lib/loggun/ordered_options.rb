module Loggun
  class OrderedOptions < Hash
    alias _get [] # preserve the original #[] method
    protected :_get # make it protected

    def []=(key, value)
      if self[key.to_sym].is_a?(Loggun::OrderedOptions) &&
         [true, false].include?(value)
        return self[key.to_sym][:enable] = value
      end

      super(key.to_sym, value)
    end

    def [](key)
      super(key.to_sym)
    end

    def method_missing(name, *args)
      name_string = +name.to_s
      if name_string.chomp!('=')
        self[name_string] = args.first
      else
        bangs = name_string.chomp!('!')

        if bangs
          self[name_string].presence || raise(KeyError, ":#{name_string} is blank")
        else
          self[name_string]
        end
      end
    end

    def respond_to_missing?(_name, _include_private)
      true
    end
  end
end
