require 'json'

class KeyManager
  KEY_PATH = "current_tokens.json"

  def initialize
    if File.exist?(KEY_PATH)
      @keys = JSON.parse(open(KEY_PATH).read, symbolize_names: true)
    end
  end

  def [](key)
    @keys[key]
  end

  def []=(key, val)
    @keys[key] = val.strip
    save
    val
  end

  def save
    open(KEY_PATH, 'w'){|f| f.write JSON.pretty_unparse @keys }
  end
end
