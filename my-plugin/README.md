# Custom Auth Plugin

Note that an additional [authservice](.pongo/authservice.yml) container will be [spinned up](.pongo/pongorc) 

```bash
pongo run -v -o gtest ./spec/myplugin/01-unit_spec.lua
pongo run -v -o gtest ./spec/myplugin/02-integration_spec.lua
```