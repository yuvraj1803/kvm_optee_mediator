set architecture aarch64
define virt_to_phys
	set $__addr = $arg0
	if ($__addr & $kern_va_lm_bit) == 0
		p/x (($__addr & (~$page_offset)) + $phys_offset)
	else
		p/x ($__addr - $kimage_voffset)
	end
end
document virt_to_phys
	Convert kernel VA to IPA and print the result.
	Usage: virt_to_phy <kernel_va>
end
define phys_to_virt
	set $__addr = $arg0
	p/x (($__addr - $phys_offset) | $page_offset)
end
document phys_to_virt
	Convert kernel IPA to linear-map VA and print the result.
	Usage: phys_to_virt <kernel_ipa>
end
define lm_alias
	virt_to_phys $arg0
	phys_to_virt $
end
document lm_alias
	Convert kernel VA to linear-map VA and print the result.
	Usage: lm_alias <kernel_va>
end
define kern_hyp_va
	set $__addr = $arg0
	p/x (($__addr & $hyp_va_mask) | $hyp_va_tag)
end
document kern_hyp_va
	Convert kernel VA to hyp VA and print the result.
	Usage: kern_hyp_va <kernel_va>
end
define sym_hyp_va
	set $__addr = (unsigned long)&$arg0
	lm_alias $__addr
	kern_hyp_va $
end
document sym_hyp_va
	Get hyp VA of an ELF symbol and print the result.
	Usage: sym_hyp_va <sym>
end
define break_nvhe
	sym_hyp_va __kvm_nvhe_$arg0
	b *$
end
define bn
	break_nvhe $arg0
end
document break_nvhe
	Set breakpoint at hyp VA of a given nVHE symbol name.
	Symbol name is provided without the "__kvm_nvhe_" prefix.
	Usage: break_nvhe <sym>
	       bn <sym>
end
file "linux/vmlinux"
# Break after memory layout constants have been computed.
tbreak apply_alternatives_all
commands
	# Cache kernel constants so they are available regardless
	# of CurrentEL.
	set $vabits_actual = 62
	set $hyp_va_tag = (tag_val << tag_lsb)
	set $hyp_va_mask = va_mask
	set $kern_va_lm_bit = (1ul << ($vabits_actual - 1))
	set $page_offset = (-(1ul << 48))
	set $phys_offset = memstart_addr
	set $kimage_voffset = kimage_voffset
	# Load the ELF again under hyp VA.
	# We use '_stext' here because 'add-symbol-file' expects address
	# of the '.text' section. '_text' corresponds to '.head.text'.
	sym_hyp_va _stext
	add-symbol-file "linux/vmlinux" $
	echo Protected KVM debug mode initialized\n
end

