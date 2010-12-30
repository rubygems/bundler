          #include "ruby.h"

          VALUE c_extension_true(VALUE self) {
            return Qtrue;
          }

          void Init_c_extension_bundle() {
            VALUE c_Extension = rb_define_class("CExtension", rb_cObject);
            rb_define_method(c_Extension, "its_true", c_extension_true, 0);
          }
