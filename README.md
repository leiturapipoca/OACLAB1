## 🔬 Implementação da Transformada Discreta de Fourier (DFT) em Assembly RISC-V

Esta seção do projeto foi dedicada à implementação completa da **Transformada Discreta de Fourier (DFT)**, um algoritmo fundamental no processamento de sinais, utilizando exclusivamente a linguagem Assembly para a arquitetura RISC-V RV32IMF.O objetivo era converter um sinal do domínio do tempo para o domínio da frequência, conforme a fórmula matemática fornecida.

A implementação foi dividida em três partes principais:

1.  **Procedimento `sincos`:** Uma função auxiliar que recebe um ângulo em radianos e retorna seu seno e cosseno.
2.  **Procedimento `DFT`:** A rotina principal que recebe um vetor de amostras `x[n]`, os ponteiros para os vetores de saída (parte real e imaginária de `X[k]`) e o número de pontos `N`, realizando o cálculo completo da transformada.
3. **Programa `main`:** Um programa principal responsável por inicializar os vetores na memória, chamar a função DFT e exibir os resultados formatados no console.

### 🛠️ Principais Desafios da Implementação

Desenvolver um algoritmo matemático complexo como a DFT em Assembly apresentou desafios únicos que exigiram um profundo entendimento da arquitetura do processador:

* **🤯 Programação em Baixo Nível:** Diferente de linguagens de alto nível, o Assembly exige o gerenciamento manual de cada recurso. Foi preciso controlar o fluxo de dados entre registradores, gerenciar o aninhamento dos loops (`k` e `n` da fórmula da DFT) e administrar a pilha de execução para chamadas de procedimento, tudo de forma explícita.

* **📐 Aproximação de Funções Trigonométricas:** A arquitetura RISC-V base não possui instruções nativas para seno e cosseno. Para implementar a função `sincos`, foi necessário recorrer a uma **aproximação por série de Taylor**. Traduzir essa expansão matemática, com suas potências e fatoriais, para operações de Assembly foi um dos maiores desafios, exigindo um controle minucioso de laços e cálculos cumulativos.

* **💹 Manipulação de Ponto Flutuante e Números Complexos:** A DFT opera inteiramente com números de ponto flutuante e resulta em um espectro de frequência complexo. Isso significou:
    * Utilizar o banco de registradores de ponto flutuante (`fa0`, `fa1`, etc.) para todos os cálculos.
    * Representar números complexos como um par de floats (parte real e imaginária).
    * Implementar a **Fórmula de Euler** ($e^{i\theta} = \cos(\theta) + i\sin(\theta)$)  para conectar o resultado do `sincos` com o cálculo principal da DFT, gerenciando a multiplicação e soma de números complexos manualmente.

* **💾 Gerenciamento de Memória:** O acesso aos vetores `x[n]`, `X_real[k]` e `X_imag[k]` foi feito através de aritmética de ponteiros. Foi necessário calcular manualmente os deslocamentos (offsets) a cada iteração para ler a amostra correta do vetor de entrada e para armazenar os resultados nos locais corretos dos vetores de saída.

* **⏱️ Análise de Desempenho:** Para avaliar a eficiência do código, foi preciso medir o tempo de execução. Isso envolveu a leitura direta dos **Registradores de Controle e Status (CSRs)**, como `time` e `instret`, para obter métricas precisas de tempo e número de instruções executadas[cite: 112, 116, 117, 118].
