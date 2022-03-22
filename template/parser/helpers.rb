class Template
  class Parser < Parslet::Parser
    class Helpers
      def self.stringify(object)
        if object.is_a?(Parslet::Slice) || object.is_a?(String)
          object.to_s
        elsif object.is_a?(Hash)
          object.transform_values { |value| stringify(value) }
        elsif object.is_a?(Array)
          object.map { |value| stringify(value) }
        elsif object.nil?
          nil
        else
          raise NotImplementedError, object.inspect
        end
      end
    end
  end
end
