## 🔧 Laboratório 2 — CPU RISC-V Uniciclo (RV32I)

Este trabalho consistiu na implementação completa de uma **CPU uniciclo compatível com a ISA RISC-V RV32I reduzida**, utilizando **Verilog** e o fluxo de síntese do **Intel Quartus Prime v24.1**.  
O objetivo foi construir, testar e validar uma arquitetura funcional capaz de executar um subconjunto essencial de instruções, além de analisar seu desempenho físico e temporal no FPGA.

---

### 🚀 Funcionalidades Implementadas

A CPU uniciclo desenvolvida suporta as seguintes instruções definidas no laboratório:

- **R-Type:** `add`, `sub`, `and`, `or`, `slt`
- **I-Type:** `lw`, `addi`, `jalr`
- **S-Type:** `sw`
- **B-Type:** `beq`
- **U-Type:** `lui`
- **J-Type:** `jal`

---

### 🧩 Principais Módulos Implementados

- **Banco de Registradores**  
  - Três portas de leitura simultâneas: `rs1`, `rs2` e `disp`  
  - Stack Pointer inicializado em `0x1001_03FC`  
- **Gerador de Imediatos** conforme tipos R, I, S, B, U e J  
- **ULA mínima**: `add`, `sub`, `and`, `or`, `slt` e detecção de zero  
- **Controlador da ULA** e **Bloco de Controle** completos  
- **Datapath Uniciclo** integrando todos os módulos  
- **Memória de Instruções e Dados** (1024 words cada), carregadas a partir dos arquivos `.mif` exportados via RARS Custom

---

### 🧪 Testes e Validação

O programa de teste **de1.s** foi utilizado para validar a implementação.  
Foram realizadas:

- **Simulação funcional** por forma de onda  
- **Simulação temporal** após síntese  
- Verificação da execução correta de todas as instruções  
- Inspeção do **RTL Viewer** para validar a estrutura do processador

---

### ⏱️ Análise Física e Temporal

- Levantamento completo dos **requisitos físicos** pós-síntese  
- Avaliação dos **slacks de setup e hold**  
- Determinação da **frequência máxima de clock** suportada pela arquitetura  
  - Obtida experimentalmente via simulação temporal ajustando a frequência no arquivo `.vwf`

---

### 🎥 Apresentação em Vídeo

O relatório final inclui também o vídeo exigido pelo laboratório, conforme instruções:

1. Apresentação do grupo, disciplina e semestre  
2. Descrição dos itens desenvolvidos  
3. Demonstração dos resultados (simulações, RTL, desempenho)  
4. Conclusões sobre o projeto  

---

### 📁 Estrutura do Projeto

- Código-fonte em Verilog (`.v`)  
- Arquivos `.mif` gerados via RARS  
- Arquivo compactado `.qar` do Quartus  
- Relatório em PDF conforme solicitado

---

### 📌 Resumo

Este laboratório proporcionou experiência prática completa no desenvolvimento de uma CPU uniciclo, integrando conceitos de ISA RISC-V, datapath, controle, implementação em HDL, simulação funcional/temporal e análise física de hardware sintetizado.

