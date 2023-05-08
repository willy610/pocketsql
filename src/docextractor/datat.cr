class Datat
  property ent_modules : Hash(String, Array(String)) = Hash(String, Array(String)).new
  # property ent_locations : Hash(String, Array(String)) = Hash(String, Array(String)).new
  property ent_classes : Hash(String, Array(String)) = Hash(String, Array(String)).new
  # property ent_constructors : Hash(String, Array(String)) = Hash(String, Array(String)).new
  property ent_methods : Hash(String, Array(String)) = Hash(String, Array(String)).new
  # property ent_instance_methods : Hash(String, Array(String)) = Hash(String, Array(String)).new
  
  # property rel_module_classmethod : Hash(String, String) = Hash(String, String).new
  # property rel_module_locations : Hash(Array(String), Array(String)) = Hash(Array(String), Array(String)).new
  property rel_class_methods : Hash(Array(String), Array(String)) = Hash(Array(String), Array(String)).new
  property rel_module_methods : Hash(Array(String), Array(String)) = Hash(Array(String), Array(String)).new
  # property rel_class_constructors : Hash(Array(String), Array(String)) = Hash(Array(String), Array(String)).new
  # property rel_class_superclass : Hash(Array(String), String) = Hash(Array(String), String).new
  # property rel_class_instance_methods : Hash(Array(String), Array(String)) = Hash(Array(String), Array(String)).new
  # property rel_class_locations : Hash(Array(String), Array(String)) = Hash(Array(String), Array(String)).new
  # property rel_class_constants : Hash(String, String) = Hash(String, String).new

  def initialize
  end
end
