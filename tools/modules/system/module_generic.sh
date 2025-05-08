# This module is used only for generating documentation. Where we use command from the menu directly, there is no module behind.
# We assume that when calling command directly, its multiarch
module_options+=(
	["module_generic,author"]="@armbian"
	["module_generic,maintainer"]="@armbian"
	["module_generic,status"]="Active"
	["module_generic,doc_link"]="https://forum.armbian.com/"
	["module_generic,arch"]="x86-64 aarch64 armhf riscv64"
)
