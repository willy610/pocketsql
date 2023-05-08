require "./ahierarch"
require "./datat"

module DocExtractor
  # ./bin/docextractor ./docs/index.json
  options = ARGV.dup
  jsonfil = options[0]? || abort "No index.json given"
  a = Datat.new
  owner_A = AHierarch::TopIn.from_json(File.read(jsonfil))
  a.ent_classes["Top Level Namespace"]=["TOPPEN"]
  owner_A.program.pick_modules(a)
  # pp a
  #
  # Entity Module
  #
  modules = a.ent_modules.map { |k, v|
    # cols = v.map { |col| "#{col}" }.join(',')
    # "#{k},#{cols}"
    [k,v].flatten.join(",")
  }.join("\n")
  File.write("./src/docextractor/data/module.csv", modules)
  #
  # Entity Class
  #
  classes = a.ent_classes.map { |k, v|
    # cols = v.map { |col| "#{col}" }.join(',')
    # "#{k},#{cols}"
    [k,v].flatten.join(",")
  }.join("\n")
  File.write("./src/docextractor/data/class.csv", classes)
  #
  # Entity Method
  #
  methods = a.ent_methods.map { |k, v|
    # cols = v.map { |col| "#{col}" }.join(',')
    # "#{k},#{cols}"
    [k,v].flatten.join(",")
  }.join("\n")
  File.write("./src/docextractor/data/method.csv", methods)
  #
  # Relation class method
  #
  classes_methods = a.rel_class_methods.map { |k, v|
    [k,v].flatten.join(",")
  }.join("\n")
  File.write("./src/docextractor/data/classmethod.csv", classes_methods)
  #
  # Relation module method
  #
  module_methods = a.rel_module_methods.map { |k, v|
    [k,v].flatten.join(",")
  }.join("\n")
  File.write("./src/docextractor/data/modulemethod.csv", module_methods)
  #
  # Entity Source (Location)
  # Collect from different sources to create the entities
  #
  # sor_from1 = a.rel_module_locations.map { |k, _|
  #   k[1]
  # }
  # sor_from2 = a.rel_class_locations.map { |k, _|
  #   k[1]
  # }
  # source = (sor_from1 | sor_from2).uniq.map { |s|
  #   cols = "#{s},more"
  # }.join("\n")

  # File.write("./src/docextractor/data/source.csv", source)
  # Entity Class
  # Collect from different sources to create the entities
  #

  #
  # ModuleLocation
  #
  # modulelocation = a.rel_module_locations.map { |k, _|
  #   "#{k[0]},#{k[1]},more"
  # }.join("\n")
  # File.write("./src/docextractor/data/modulesource.csv", modulelocation)
end
