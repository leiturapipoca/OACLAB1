O mais importante se encontra nos arquivos .v. O ramD e ramI não precisam de mudanças

## 🔧 Laboratório 3 — CPU RISC-V Multiciclo (RV32I)

Este projeto consistiu na implementação completa de uma **CPU Multiciclo** compatível com a ISA **RISC-V RV32I reduzida**, utilizando **Verilog** e o ambiente de síntese **Intel Quartus Prime**.  
O objetivo foi expandir o processador do laboratório anterior, introduzindo um caminho de dados multietapa com controle sequencial via máquina de estados.

---

### 🚀 Funcionalidades Implementadas

A CPU multiciclo suporta o mesmo conjunto de instruções do laboratório anterior, porém distribuídas em múltiplos ciclos de clock:

- **R-Type:** `add`, `sub`, `and`, `or`, `slt`
- **I-Type:** `lw`, `addi`, `jalr`
- **S-Type:** `sw`
- **B-Type:** `beq`
- **U-Type:** `lui`
- **J-Type:** `jal`

O projeto reutiliza os módulos previamente desenvolvidos:  
**Banco de Registradores**, **Gerador de Imediatos**, **ULA**, **Controlador da ULA**, e o programa de teste **de1.s**.

---

### 🧩 Pontos-Chave do Projeto

#### ✔ Integração das Memórias na Arquitetura Von Neumann
- Código e dados compartilham a mesma memória.  
- Foi implementado um **controle unificado**, onde a seleção entre memória de instruções e de dados é feita **exclusivamente pelo endereço**.  
- Assim, ambas usam o mesmo bloco físico, com lógica de seleção interna.

#### ✔ Otimização do Acesso à Memória (2 ciclos)
O IP de memória do Quartus exige **2 ciclos para leitura/escrita**.  
Para isso, o **diagrama de estados** foi ajustado para incluir:
- ciclo de requisição de memória  
- ciclo de espera (stall implícito)  
- execução da próxima etapa apenas após `mem_ready`

Isso reduz o número de estados extras e torna o acesso mais previsível.

#### ✔ Bloco Controlador e Máquina de Estados
Foi implementado um **controle sequencial completo**, responsável por coordenar:
- fetch → decode → execute → memory → write-back  
- sinais de controle para multiplexadores, registradores intermediários e escrita na memória  
- caminhos específicos para instruções com fluxos longos (como `lw` e `jal`)

A máquina de estados inclui:
- estados comuns a todas as instruções  
- ramos especializados para load/store, branch, jump e operações R-Type

---

### 🧪 Testes e Validação

Com o programa **de1.s**, foram realizados:

- ✔ **Simulação funcional** (forma de onda)  
- ✔ **Simulação temporal** após síntese  
- ✔ Verificação da execução correta de todas as instruções  
- ✔ Análise do **RTL Viewer** para inspeção da arquitetura multiciclo

---

### ⏱️ Análise Física e Temporal

Foram obtidos:

- Requisitos físicos e temporais completos pós-síntese  
- Verificação dos slacks de **setup** e **hold**  
- Determinação experimental da **frequência máxima de clock utilizável** pela CPU  
  - Feito variando a frequência no arquivo `.vwf` e observando falhas de temporização

---

### 🎥 Apresentação em Vídeo

O relatório acompanha a apresentação obrigatória, contendo:

1. Introdução do grupo e da disciplina  
2. Explicação dos itens avaliados  
3. Demonstração da CPU multiciclo em simulação  
4. Conclusões gerais sobre o desempenho e implementação

---

### 📁 Conteúdo do Projeto

- Código-fonte em Verilog (`.v`)  
- Arquivo `.qar` do Quartus com o projeto completo  
- Simulações (`.vwf`)  
- Relatório em PDF  
- Máquina de estados, diagrama e capturas de RTL Viewer  

---

### 📌 Resumo

O laboratório aprofundou o entendimento do ciclo de instrução, controle sequencial, temporização e abertura crítica.  
A implementação final resultou em uma **CPU Multiciclo funcional**, validada em simulação funcional e temporal, seguindo fielmente o padrão da ISA RV32I reduzida.
