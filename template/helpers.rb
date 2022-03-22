class Template
  class Helpers
    class Error
      attr_reader :parent, :pos, :message, :source, :children

      def initialize(parent:, pos:, message:, source:, children:)
        @parent = parent
        @pos = pos.charpos
        @message = message.to_s
        @source = source.instance_variable_get(:@str).string
        @children = children
      end
    end

    def self.sanitize(object)
      if object.is_a?(Parslet::Slice) || object.is_a?(String)
        object.to_s
      elsif object.is_a?(Hash)
        object.transform_values { |value| sanitize(value) }
      elsif object.is_a?(Array)
        object.map { |value| sanitize(value) }
      elsif object.nil?
        nil
      else
        raise NotImplementedError, object.class
      end
    end

    def self.print(object)
      pp sanitize(object)
    end

    def self.error(e, trace: false)
      error = parse_error(e.parse_failure_cause).flatten.sort_by(&:pos).last
      if trace
        errors = [error]
        errors << error while error = error.parent
        errors.reverse.each.with_index do |error, index|
          print_error(error, index: index)
        end
      else
        print_error(error)
      end
    end

    def self.print_error(error, index: 0)
      puts "  " * index + error.message
      puts "  " * index + error.source
      puts "  " * index + " " * error.pos + "^"
    end

    def self.parse_error(error, parent: nil)
      error = Template::Helpers::Error.new(
        pos: error.pos,
        message: error.message,
        source: error.source,
        parent: parent,
        children: error.children,
      )

      [error] + error.children.map { |child| parse_error(child, parent: error) }
    end
  end
end
