class << RSpec::OpenAPI::SchemaMerger = Object.new
  # @param [Hash] base
  # @param [Hash] spec
  def reverse_merge!(base, spec)
    spec = normalize_keys(spec)
    deep_reverse_merge!(base, spec)
  end

  private

  def normalize_keys(spec)
    case spec
    when Hash
      spec.map do |key, value|
        [key.to_s, normalize_keys(value)]
      end.to_h
    when Array
      spec.map { |s| normalize_keys(s) }
    else
      spec
    end
  end

  # Not doing `base.replace(deep_merge(base, spec))` to preserve key orders.
  # Also this needs to be aware of OpenAPI details unlike an ordinary deep_reverse_merge
  # because a Hash-like structure may be an array whose Hash elements have a key name.
  #
  # TODO: Perform more intelligent merges like rerouting edits / merging types
  # TODO: Should we probably force-merge `summary` regardless of manual modifications?
  def deep_reverse_merge!(base, spec)
    spec.each do |key, value|
      if base[key].is_a?(Hash) && value.is_a?(Hash)
        deep_reverse_merge!(base[key], value)
      elsif !base.key?(key)
        base[key] = value
      elsif base[key].is_a?(Array) && value.is_a?(Array)
        # parameters need to be merged as if `name` and `in` were the Hash keys.
        if key == 'parameters'
          base[key] |= value
          base[key].uniq! { |param| param.slice('name', 'in') }
        end
      else
        # no-op
      end
    end
    base
  end
end
