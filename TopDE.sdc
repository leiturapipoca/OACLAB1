# 1. Define o clock principal (da memória) com o seu período de 20ns
create_clock -name CLOCK_MEM -period 20.0 [get_ports {CLOCK}]

# 2. Define o clock da CPU (ClockDIV) como um clock gerado, 4x mais lento
create_generated_clock -name CLOCK_CPU -source [get_ports {CLOCK}] -divide_by 4 [get_ports {ClockDIV}]