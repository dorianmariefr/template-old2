class Template
  class Node
    class Nodes < Node
      attr_reader :children

      def to_h
        children.map(&:to_h)
      end
    end

    class Template < Nodes
      def initialize(parsed)
        @children =
          parsed.map do |node|
            if node.key?(:text)
              Text.new(node[:text])
            elsif node.key?(:code)
              Code.new(node[:code])
            else
              raise NotImplementedError, node.inspect
            end
          end
      end

      def self.parse(source)
        new(::Template::Parser.new.parse(source))
      end
    end

    class Text < Node
      attr_reader :value

      def initialize(parsed)
        @value = parsed
      end
    end

    class Code < Nodes
      def initialize(parsed)
        @children = parsed.map { |node| Statement.from(node) }
      end
    end

    class Call < Node
      attr_reader :name, :operator, :call, :arguments

      def initialize(parsed)
        @name = Name.new(parsed.delete(:name))
        @operator = Operator.new(parsed.delete(:operator)) if parsed.key?(:operator)
        @call = Call.new(parsed.delete(:call)) if parsed.key?(:call)
        @arguments = Values.new(parsed.delete(:arguments)) if parsed.key?(:arguments)
        raise parsed.inspect if parsed.any?
      end
    end

    class Name < Node
      attr_reader :value

      def initialize(parsed)
        @value = parsed
      end
    end

    class If < Node
      attr_reader :if_statement, :if_body

      def initialize(parsed)
        @if_statement = Statement.from(parsed.delete(:if_statement))
        @if_body = Body.from(parsed.delete(:if_body))
        raise parsed.inspect if parsed.any?
      end
    end

    class Operator < Node
      attr_reader :value

      def initialize(parsed)
        @value = parsed
      end
    end

    class Values < Nodes
      def initialize(parsed)
        @children = list(parsed).map { |node| Value.from(node) }
      end
    end

    class Arguments < Nodes
      def initialize(parsed)
        @children = list(parsed).map { |node| Argument.new(node) }
      end
    end

    class Argument < Node
      attr_reader :value

      def initialize(parsed)
        @value = Value.from(parsed.delete(:value))

        raise parsed.inspect if parsed.any?
      end
    end

    class Define < Node
      attr_reader :name, :arguments, :body

      def initialize(parsed)
        @name = Name.new(parsed.delete(:name))

        if parsed.key?(:arguments)
          @arguments = Arguments.new(parsed.delete(:arguments))
        end

        if parsed.key?(:body)
          @body = Body.from(parsed.delete(:body))
        end

        raise parsed.inspect if parsed.any?
      end
    end

    class String < Node
      attr_reader :value

      def initialize(parsed)
        @value = parsed
      end
    end

    class Statement
      def self.from(parsed)
        if parsed.key?(:if)
          If.new(parsed[:if])
        elsif parsed.key?(:define)
          Define.new(parsed[:define])
        else
          Value.from(parsed)
        end
      end
    end

    class Body
      def self.from(parsed)
        if parsed.key?(:template)
          Template.new(parsed[:template])
        else
          raise NotImplementedError, parsed.inspect
        end
      end
    end

    class Value
      def self.from(parsed)
        if parsed.key?(:call)
          Call.new(parsed[:call])
        elsif parsed.key?(:string)
          String.new(parsed[:string])
        else
          raise NotImplementedError, parsed.inspect
        end
      end
    end

    def to_h
      instance_variables.map do |name|
        instance_variable = instance_variable_get(name)

        if instance_variable.is_a?(Node)
          instance_variable = instance_variable.to_h
        elsif instance_variable.is_a?(Parslet::Slice)
          instance_variable = instance_variable.to_s
        end

        [name.to_s[1..-1].to_sym, instance_variable]
      end.to_h
    end

    private

    def list(parsed)
      l = []
      l << parsed[:first] if parsed[:first]
      l << parsed[:second] if parsed[:second]
      l += parsed[:others] if parsed[:others]
      l
    end
  end
end
