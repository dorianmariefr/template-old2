class Template
  class Node
    class Helpers
      def self.names_of(object)
        if object.is_a?(Template::Node)
          object.class.name.split('::').last
        elsif object.is_a?(Array)
          object.map { |value| names_of(value) }
        else
          raise NotImplementedError, object.inspect
        end
      end
    end
  end
end
