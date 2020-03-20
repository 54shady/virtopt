set $x=4
while $x--
set $module_entry=init_type_list[$x].tqh_first
while $module_entry != 0x0
p $module_entry.init
set $module_entry=$module_entry.node.tqe_next
end
end
