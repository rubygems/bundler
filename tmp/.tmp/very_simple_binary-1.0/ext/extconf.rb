          require "mkmf"

          # exit 1 unless with_config("simple")

          extension_name = "very_simple_binary_c"
          dir_config extension_name
          create_makefile extension_name
