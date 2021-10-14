require 'yaml'
require 'json'

# Script to convert existing YAML files.
# TODO: Remove this script

Dir['ast/*.yaml'].each do |f|
  ob = YAML.load_file(f)
  if String === ob['expected']
    ob2 = {
      "expression" => ob['expression'],
      "expected_ast" => JSON.parse(ob['expected'])
    }
    File.open(f, 'w') { |file| file.write(ob2.to_yaml) }
  end
end

Dir['expression/*.yaml'].each do |f|
  ob = YAML.load_file(f)
  if String === ob['expected']
    ob2 = {
      "expression" => ob['expression'],
      "text" => ob['text'],
      "expected_args" => JSON.parse(ob['expected'])
    }
    File.open(f, 'w') { |file| file.write(ob2.to_yaml) }
  end
end

Dir['regex/*.yaml'].each do |f|
  ob = YAML.load_file(f)
  if String === ob['expected']
    ob2 = {
      "expression" => ob['expression'],
      "expected_regex" => ob['expected']
    }
    File.open(f, 'w') { |file| file.write(ob2.to_yaml) }
  end
end

Dir['tokens/*.yaml'].each do |f|
  ob = YAML.load_file(f)
  if String === ob['expected']
    ob2 = {
      "expression" => ob['expression'],
      "expected_tokens" => JSON.parse(ob['expected'])
    }
    File.open(f, 'w') { |file| file.write(ob2.to_yaml) }
  end
end
