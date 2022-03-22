class Template
  class Node
    class Text < Template::Node
      def transform
        self
      end
    end

    class Code < Template::Node
      def transform
      end
    end

    class Call < Template::Node
    end

    class Name < Template::Node
    end

    attr_reader :parsed

    def initialize(parsed)
      @parsed = parsed
    end
  end
end
