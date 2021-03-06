# frozen_string_literal: true

module Syspro
  # This class represents a syspro response
  class SysproObject
    include Enumerable

    def initialize(id = nil, opts = {})
      @opts = Util.normalize_opts(opts)
      @original_values = {}
      @values = {}

      # This really belongs in APIResource, but not putting it there allows us
      # to have a unified inspect method
      @unsaved_values = Set.new
      @transient_values = Set.new
      @values[:id] = id if id
    end

    # Determines the equality of two Syspro objects. Syspro objects are
    # considered to be equal if they have the same set of values and each one
    # of those values is the same.
    def ==(other)
      other.is_a?(SysproObject) &&
        @values == other.instance_variable_get(:@values)
    end

    def to_s(*_args)
      JSON.pretty_generate(to_hash)
    end

    def inspect
      id_string = respond_to?(:id) && !id.nil? ? " id=#{id}" : ''
      "#<#{self.class}:0x#{object_id.to_s(16)}#{id_string}> JSON: " + JSON.pretty_generate(@values) # rubocop:disable Metrics/LineLength
    end

    def keys
      @values.keys
    end

    def values
      @values.values
    end

    def to_hash # rubocop:disable Metrics/MethodLength
      maybe_to_hash = lambda do |value|
        value.respond_to?(:to_hash) ? value.to_hash : value
      end

      @values.each_with_object({}) do |(key, value), acc|
        acc[key] = case value
                   when Array
                     value.map(&maybe_to_hash)
                   else
                     maybe_to_hash.call(value)
                   end
      end
    end

    def each(&blk)
      @values.each(&blk)
    end

    # Produces a deep copy of the given object including support for arrays,
    # hashes, and SysproObjects.
    def self.deep_copy(obj) # rubocop:disable Metrics/MethodLength
      case obj
      when Array
        obj.map { |e| deep_copy(e) }
      when Hash
        obj.each_with_object({}) do |(k, v), copy|
          copy[k] = deep_copy(v)
          copy
        end
      when SysproObject
        obj.class.construct_from(
          deep_copy(obj.instance_variable_get(:@values)),
          obj.instance_variable_get(:@opts).select do |k, _v|
            Util::OPTS_COPYABLE.include?(k)
          end
        )
      else
        obj
      end
    end
    private_class_method :deep_copy
  end
end
