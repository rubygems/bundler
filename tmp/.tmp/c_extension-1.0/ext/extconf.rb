          require "mkmf"
          name = "c_extension_bundle"
          dir_config(name)
          raise "OMG" unless with_config("c_extension") == "hello"
          create_makefile(name)
