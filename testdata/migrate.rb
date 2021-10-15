require 'yaml'
require 'json'

Dir['**/*.yaml'].each do |f|
  ob = YAML.load_file(f)
  File.open(f, 'w') { |file| file.write(ob.to_yaml) }
end
