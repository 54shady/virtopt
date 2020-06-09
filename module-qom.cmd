set $miq=init_type_list[MODULE_INIT_QOM].tqh_first
while $miq != 0x0
p $miq.init
set $miq=$miq.node.tqe_next
end
