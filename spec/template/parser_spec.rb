require_relative '../../template'

RSpec.describe Template::Parser do
  let!(:template) { '' }

  subject do
    Template::Helpers.sanitize(described_class.new.parse(template))
  rescue Parslet::ParseFailed => e
    puts e.parse_failure_cause.ascii_tree
    raise e
  end

  def matches_code(code)
    is_expected.to eq([{ code: [code] }])
  end

  it { is_expected.to eq([{ text: '' }]) }

  context 'with only text' do
    let!(:template) { 'Hello' }
    it { is_expected.to eq([{ text: 'Hello' }]) }
  end

  context 'nothing' do
    let!(:template) { '{nothing}' }
    it { matches_code(nothing: 'nothing') }
  end

  context 'boolean' do
    context 'true' do
      let!(:template) { '{true}' }
      it { matches_code(boolean: 'true') }
    end

    context 'false' do
      let!(:template) { '{false}' }
      it { matches_code(boolean: 'false') }
    end
  end

  context 'with an interpolation' do
    let!(:template) { 'Hello {user.first_name}' }
    it do
      is_expected.to eq(
        [
          { text: 'Hello ' },
          {
            code: [
              {
                call: {
                  name: 'user',
                  operator: '.',
                  call: {
                    name: 'first_name'
                  }
                }
              }
            ]
          }
        ]
      )
    end
  end

  context 'with an escaped interpolation' do
    let!(:template) { "Hello \\{\\{user.first_name\\}\\}" }
    it { is_expected.to eq([{ text: 'Hello {{user.first_name}}' }]) }
  end

  context 'with an code' do
    let!(:template) { '{users.pop}' }
    it do
      is_expected.to eq(
        [
          {
            code: [
              { call: { name: 'users', operator: '.', call: { name: 'pop' } } }
            ]
          }
        ]
      )
    end
  end

  context 'strings' do
    def matches_string(string)
      is_expected.to eq([{ code: [{ string: [{ text: string }] }] }])
    end

    context 'double quote' do
      let!(:template) { '{"Hello"}' }
      it { matches_string('Hello') }
    end

    context 'single quote' do
      let!(:template) { "{'Hello'}" }
      it { matches_string('Hello') }
    end

    context 'escaped characters' do
      let!(:template) { "{'Dorian\\'s\\nOr not'}" }
      it { matches_string("Dorian's\\nOr not") }
    end

    context 'interpolation' do
      let!(:template) { '{"Hello {user}"}' }

      it do
        matches_code(
          string: [{ text: 'Hello ' }, { code: [{ call: { name: 'user' } }] }]
        )
      end
    end

    context 'short string' do
      let!(:template) { '{:name}' }
      it { matches_code(string: 'name') }
    end
  end

  context 'lists' do
    context 'explicit list' do
      let!(:template) { '{[true, false, nothing]}' }

      it do
        matches_code(
          list: {
            first: {
              boolean: 'true'
            },
            others: [{ boolean: 'false' }, { nothing: 'nothing' }]
          }
        )
      end
    end

    context 'implicit list' do
      let!(:template) { '{true, false, nothing}' }

      it do
        matches_code(
          list: {
            first: {
              boolean: 'true'
            },
            second: {
              boolean: 'false'
            },
            others: [{ nothing: 'nothing' }]
          }
        )
      end
    end

    context 'nested list' do
      let!(:template) { '{true, [false, true], nothing}' }

      it do
        matches_code(
          list: {
            first: {
              boolean: 'true'
            },
            second: {
              list: {
                first: {
                  boolean: 'false'
                },
                others: [{ boolean: 'true' }]
              }
            },
            others: [{ nothing: 'nothing' }]
          }
        )
      end
    end
  end

  context 'dictionnaries' do
    context 'explicit dictionnary with single key value pair' do
      let!(:template) { '{{name: "Dorian"}}' }

      it do
        matches_code(
          dictionnary: {
            first: {
              key: {
                string: 'name'
              },
              value: {
                string: [{ text: 'Dorian' }]
              }
            },
            others: []
          }
        )
      end
    end

    context 'explicit dictionnary with multiple key value pairs' do
      let!(:template) { '{{name: "Dorian", twitter: "@dorianmariefr"}}' }

      it do
        matches_code(
          dictionnary: {
            first: {
              key: {
                string: 'name'
              },
              value: {
                string: [{ text: 'Dorian' }]
              }
            },
            others: [
              {
                key: {
                  string: 'twitter'
                },
                value: {
                  string: [{ text: '@dorianmariefr' }]
                }
              }
            ]
          }
        )
      end
    end

    context 'implicit dictionnary with single key value pair' do
      let!(:template) { '{name: "Dorian"}' }

      it do
        matches_code(
          dictionnary: {
            first: {
              key: {
                string: 'name'
              },
              value: {
                string: [{ text: 'Dorian' }]
              }
            },
            others: []
          }
        )
      end
    end

    context 'implicit dictionnary with multiple key value pairs' do
      let!(:template) { '{name: "Dorian", twitter: "@dorianmariefr"}' }

      it do
        matches_code(
          dictionnary: {
            first: {
              key: {
                string: 'name'
              },
              value: {
                string: [{ text: 'Dorian' }]
              }
            },
            others: [
              {
                key: {
                  string: 'twitter'
                },
                value: {
                  string: [{ text: '@dorianmariefr' }]
                }
              }
            ]
          }
        )
      end
    end
  end

  context 'implicit dictionnary inside a list' do
    let!(:template) { '{1, name: "Dorian"}' }

    it do
      matches_code(
        list: {
          first: {
            number: {
              base_10: {
                whole: '1'
              }
            }
          },
          second: {
            dictionnary: {
              first: {
                key: {
                  string: 'name'
                },
                value: {
                  string: [{ text: 'Dorian' }]
                }
              },
              others: []
            }
          },
          others: []
        }
      )
    end
  end

  context 'calls' do
    context 'with no arguments and no parenthesis' do
      let!(:template) { '{name.split}' }

      it do
        matches_code(
          call: {
            name: 'name',
            operator: '.',
            call: {
              name: 'split'
            }
          }
        )
      end
    end

    context 'with no arguments and parenthesis' do
      let!(:template) { '{name.split()}' }

      it do
        matches_code(
          call: {
            name: 'name',
            operator: '.',
            call: {
              name: 'split',
              arguments: ''
            }
          }
        )
      end
    end

    context 'with single argument' do
      let!(:template) { '{name.split(" ")}' }

      it do
        matches_code(
          call: {
            name: 'name',
            operator: '.',
            call: {
              name: 'split',
              arguments: {
                first: {
                  string: [{ text: ' ' }]
                },
                others: []
              }
            }
          }
        )
      end
    end

    context 'with multiple arguments' do
      let!(:template) { '{name.split(" ", 2)}' }

      it do
        matches_code(
          call: {
            name: 'name',
            operator: '.',
            call: {
              name: 'split',
              arguments: {
                first: {
                  string: [{ text: ' ' }]
                },
                others: [{ number: { base_10: { whole: '2' } } }]
              }
            }
          }
        )
      end
    end
  end

  context 'define' do
    context 'function with no arguments and inline body' do
      let!(:template) { '{define title "Home" end}' }

      it do
        matches_code(
          define: {
            name: 'title',
            body: [{ string: [{ text: 'Home' }] }]
          }
        )
      end
    end

    context 'function with no arguments and text body' do
      let!(:template) { '{define title}Home{end}' }

      it do
        matches_code(
          define: {
            name: 'title',
            body: {
              template: [{ text: 'Home' }]
            }
          }
        )
      end
    end

    context 'function with empty arguments and inline body' do
      let!(:template) { '{define title() "Home" end}' }

      it do
        matches_code(
          define: {
            name: 'title',
            arguments: '',
            body: [{ string: [{ text: 'Home' }] }]
          }
        )
      end
    end

    context 'function with single arguments and inline body' do
      let!(:template) { '{define title() "Home" end}' }

      it do
        matches_code(
          define: {
            name: 'title',
            arguments: '',
            body: [{ string: [{ text: 'Home' }] }]
          }
        )
      end
    end

    context 'with with default argument' do
      let!(:template) { '{define link_to(text, url = "/") end}' }

      it do
        matches_code(
          define: {
            name: 'link_to',
            body: nil,
            arguments: {
              first: {
                value: {
                  call: {
                    name: 'text'
                  }
                }
              },
              others: [
                value: {
                  call: {
                    name: 'url'
                  }
                },
                default: {
                  string: [{ text: '/' }]
                }
              ]
            }
          }
        )
      end
    end

    context 'with with default keyword argument' do
      let!(:template) do
        '{define order(column: :created_at, direction: :asc) end}'
      end

      it do
        matches_code(
          define: {
            name: 'order',
            body: nil,
            arguments: {
              first: {
                value: 'column',
                default: {
                  string: 'created_at'
                }
              },
              others: [value: 'direction', default: { string: 'asc' }]
            }
          }
        )
      end
    end
  end

  context 'if, else if, else' do
    context 'if value' do
      let!(:template) { '{if item.parent}{render(item.parent)}{end}' }

      it do
        matches_code(
          if: {
            if_statement: {
              call: {
                name: 'item',
                operator: '.',
                call: {
                  name: 'parent'
                }
              }
            },
            if_body: {
              template: [
                {
                  code: [
                    {
                      call: {
                        name: 'render',
                        arguments: {
                          first: {
                            call: {
                              name: 'item',
                              operator: '.',
                              call: {
                                name: 'parent'
                              }
                            }
                          },
                          others: []
                        }
                      }
                    }
                  ]
                }
              ]
            }
          }
        )
      end
    end

    context 'else' do
      let!(:template) { '{if guest}Guest{else}Not guest{end}' }
      it do
        matches_code(
          if: {
            else_body: {
              template: [{ text: 'Not guest' }]
            },
            if_body: {
              template: [{ text: 'Guest' }]
            },
            if_statement: {
              call: {
                name: 'guest'
              }
            }
          }
        )
      end
    end

    context 'else if' do
      let!(:template) { '{if guest}Guest{else if user}User{end}' }
      it do
        matches_code(
          if: {
            else_if_body: {
              template: [{ text: 'User' }]
            },
            else_if_statement: {
              call: {
                name: 'user'
              }
            },
            if_body: {
              template: [{ text: 'Guest' }]
            },
            if_statement: {
              call: {
                name: 'guest'
              }
            }
          }
        )
      end
    end

    context 'else if and else' do
      let!(:template) { '{if admin}Admin{else if user}User{else}Guest{end}' }
      it do
        matches_code(
          if: {
            else_body: {
              template: [{ text: 'Guest' }]
            },
            else_if_body: {
              template: [{ text: 'User' }]
            },
            else_if_statement: {
              call: {
                name: 'user'
              }
            },
            if_body: {
              template: [{ text: 'Admin' }]
            },
            if_statement: {
              call: {
                name: 'admin'
              }
            }
          }
        )
      end
    end
  end

  context 'real world template' do
    let!(:template) { <<~TEMPLATE }
      {define render(item)}
        <p>{link_to(item.user.name, item.user.url)}</p>

        {markdown(item.content)}

        <p>{link_to(item.created_at.to_formatted_s(:long), item.url)}</p>

        {if item.parent}
          {render(item.parent)}
        {end}
      {end}

      {render(item)}
      TEMPLATE

    it { expect { subject }.to_not raise_error }
  end
end
