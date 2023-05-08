require "json"

module AHierarch
  class TopIn
    include JSON::Serializable
    property repository_name : String
    property body : String
    property program : Type
  end

  class RelativeLocation
    include JSON::Serializable
    property filename : String
    propertyline_number : Int32
    propertyurl : String
  end

  class Type
    include JSON::Serializable
    property html_id : String?
    property path : String?
    property kind : String?
    property full_name : String?
    property name : String?
    property abstract : Bool?
    property superclass : TypeRef?
    property ancestors : Array(TypeRef) = [] of TypeRef
    property locations : Array(RelativeLocation) = [] of RelativeLocation
    property repository_name : String?
    property program : Bool?
    property enum : Bool?
    property alias : Bool?
    property aliased : String?
    property const : Bool?
    property constants : Array(Constant) = [] of Constant
    property included_modules : Array(TypeRef) = [] of TypeRef
    property extended_modules : Array(TypeRef) = [] of TypeRef
    property subclasses : Array(TypeRef) = [] of TypeRef
    property including_types : Array(TypeRef) = [] of TypeRef
    property namespace : TypeRef?
    property doc : String?
    property summary : String?
    property class_methods : Array(Method) = [] of Method
    property constructors : Array(Method) = [] of Method
    property instance_methods : Array(Method) = [] of Method
    property macros : Array(Macro) = [] of Macro
    property types : Array(Type) = [] of Type

    def pick_modules(d : Datat)
      #
      # Module

      if @kind == "module"
        #
        # if try_full_module_name = @full_name
          if try_full_module_name = @name
            # DEFINE THE 'module'
          if d.ent_modules.has_key?(try_full_module_name)
            raise "d.ent_modules.has_key '#{try_full_module_name}'"
          else
            d.ent_modules[try_full_module_name] = ["HTMLID"]
          end
          @class_methods.each { |a_Method|
            d.ent_methods[a_Method.name] = ["HTMLID"]
            d.rel_module_methods[[try_full_module_name, a_Method.name]] = ["HTMLID"]
          }
          @constructors.each { |a_Method|
            d.ent_methods[a_Method.name] = ["HTMLID"]
            d.rel_module_methods[[try_full_module_name, a_Method.name]] = ["HTMLID"]
          }
          @instance_methods.each { |a_Method|
            d.ent_methods[a_Method.name] = ["HTMLID"]
            d.rel_module_methods[[try_full_module_name, a_Method.name]] = ["HTMLID"]
          }
        end
        # Deeper down. Assuming 'module' is the 'type' at top
        @types.each { |t|
          # puts "!" + __FILE__ + ":" + __LINE__.to_s
          # puts t.kind

          t.pick_modules(d)
        }
        # end
        #
        # Class
        #
      elsif @kind == "class"
        # if try_full_class_name = @full_name
          if try_full_class_name = @name
            d.ent_classes[try_full_class_name] = ["HTMLID"]
          @class_methods.each { |a_Method|
            d.ent_methods[a_Method.name] = ["HTMLID"]
            d.rel_class_methods[[try_full_class_name, a_Method.name].dup] = ["HTMLID"]
          }
          @constructors.each { |a_Method|
            d.ent_methods[a_Method.name] = ["HTMLID"]
            d.rel_class_methods[[try_full_class_name, a_Method.name].dup] = ["HTMLID"]
          }
          @instance_methods.each { |a_Method|
            d.ent_methods[a_Method.name] = ["HTMLID"]
            d.rel_class_methods[[try_full_class_name, a_Method.name].dup] = ["HTMLID"]
          }

          # constants
          # @constants.each { |a_Constant|
          #   d.rel_class_constants[try_full_class_name] = a_Constant.name
          # }
        end
      else
        puts "NOT acted on: @kind @full_name #{@kind} #{@full_name}"
      end # end
    end
  end

  class TypeRef
    include JSON::Serializable
    property html_id : String?
    property kind : String
    property full_name : String
    property name : String

    def to_s(io : IO)
      io << kind << ' ' << full_name
    end
  end

  class Constant
    include JSON::Serializable
    property name : String
    property value : String
    property doc : String?
    property summary : String?
  end

  class Macro
    include JSON::Serializable
    property id : String?
    property html_id : String
    property name : String
    property doc : String?
    property summary : String?
    property abstract : Bool
    property args : Array(Argument) = [] of Argument
    property args_string : String?
    property source_link : String?
    property def : CrystalMacro
  end

  class Method
    include JSON::Serializable
    property id : String?
    property html_id : String
    property name : String
    property doc : String?
    property summary : String?
    property abstract : Bool
    property args : Array(Argument) = [] of Argument
    property args_string : String?
    property source_link : String?
    property def : CrystalDef

    def return_type
      self.def.return_type
    end
  end

  class Argument
    include JSON::Serializable
    property name : String
    property doc : String?
    property default_value : String?
    property external_name : String?
    property restriction : String?

    def to_s(io : IO)
      io << name << " (" << restriction << ")"
    end
  end

  class CrystalDef
    include JSON::Serializable
    property name : String
    property args : Array(Argument) = [] of Argument
    property double_splat : Argument?
    property splat_index : Int32?
    property yields : Int32?
    property block_arg : Argument?
    property return_type : String?
    property visibility : String
    property body : String
  end

  class CrystalMacro
    include JSON::Serializable
    property args : Array(Argument) = [] of Argument
    property double_splat : Argument?
    property splat_index : Int32?
    property block_arg : Argument?
    property visibility : String
    property body : String
  end
end
