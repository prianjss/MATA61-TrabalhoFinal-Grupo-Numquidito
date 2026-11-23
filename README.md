# DivaLang — Compilador (MATA61)

**Disciplina:** MATA61 – Compiladores (UFBA)
**Entrega:** M2 – Análise Léxica e Sintática (sem ações semânticas)

---

## 👥 Integrantes do Grupo

* Beatriz Pereira Espinheira
* Edwu Morais Braga
* Priscila Anjos Santos
* Rian Victor Pereira Ribeiro

---

## 1. Sobre o Projeto e a Linguagem

A **DivaLang** é uma linguagem de programação imperativa de propósito introdutório, desenvolvida como projeto final da disciplina de Compiladores da Universidade Federal da Bahia (UFBA). A proposta da linguagem é combinar uma sintaxe limpa e legível inspirada no **Python** (com blocos definidos por indentação e uso de dois-pontos `:`) com palavras-chave lúdicas baseadas na cultura pop e no vocabulário digital.

Este repositório contém a implementação da etapa **M2**, focada no **Front-end** do compilador (análise léxica utilizando **Flex** e análise sintática utilizando **Bison**), estruturada de forma puramente sintática **sem ações semânticas**.

---

## 2. Especificação da Linguagem (Implementado na M2)

### Palavras Reservadas Implementadas

Restringimos o escopo do compilador às seguintes palavras-chave essenciais:

* `lacrou`: Estrutura condicional (`if`)
* `gag`: Bloco alternativo da condicional (`else`)
* `babado`: Laço de repetição contado (`for`)
* `na`: Operador de pertinência utilizado no laço (`in`)
* `turne`: Gerador de sequência numérica / intervalo (`range`)
* `flash`: Comando de saída para exibir valores na tela (`print`)

### Operadores Básicos e Relacionais

O analisador léxico e sintático reconhece os seguintes operadores e símbolos:

* **Atribuição:** `=`
* **Operadores Aritméticos:** Soma (`+`), Subtração (`-`), Multiplicação (`*`) e Divisão (`/`).
* **Operadores Relacionais (para comparações em condições):** Igual (`==`), Diferente (`!=`), Maior que (`>`), Menor que (`<`), Maior ou igual (`>=`) e Menor ou igual (`<=`). Como na especificação (seção 4.2), não têm associatividade: comparações encadeadas como `1 < x < 5` são erro sintático.
* **Delimitadores e Estrutura:** Parênteses `( )` para precedência e argumentos, dois-pontos `:` para iniciar blocos, vírgula `,` para separar itens, além de quebras de linha (`NEWLINE`) e controle de indentação (`INDENT` / `DEDENT`).

---

## 3. Justificativa de Redução de Escopo

Durante o planejamento e evolução da especificação conceitual da DivaLang, a equipe optou conscientemente por **reduzir e enxugar o escopo** técnico implementado nesta fase prática em relação à documentação teórica inicial (M1).

### Por que decidimos reduzir o escopo?

A especificação original contemplava múltiplos comandos complexos e redundantes (como laços `cunt` paralelos, controles de salto como `old` e `flope`, leitura de terminal `tea` e conversões de tipos estritas `hit` e `trah`). Manter esse conjunto completo geraria complexidade excessiva na Gramática Livre de Contexto (GLC), aumentando drasticamente o risco de conflitos de *shift/reduce* e *reduce/reduce* no Bison, além de comprometer o cumprimento do cronograma da disciplina.

### O que ficou fora desta entrega

Em relação à especificação da M1 (seções 2.1, 2.2 e 4.3), os itens abaixo **não** foram implementados nesta etapa:

| Categoria | Itens da M1 | Como o analisador atual trata |
|---|---|---|
| Laço com condição | `cunt` (while) | lido como identificador; `cunt x < 3:` é erro sintático |
| Controle de laço e bloco vazio | `old` (continue), `flope` (break), `passada` (pass) | lidos como identificadores; sozinhos na linha, são erro sintático |
| Entrada e conversões | `tea` (input), `hit` (int), `trah` (float) | lidos como identificadores; chamadas como `hit(3.7)` são erro sintático |
| Literais | `real`, `fake`, `nada` | lidos como identificadores comuns (ex.: `x = real` é aceito) |
| Operadores lógicos | `e`, `ou`, `nao` e seus níveis de precedência (1 a 3 da seção 4.2) | lidos como identificadores; `a < b e c` é erro sintático |
| Operadores aritméticos | `//` (divisão inteira) e `%` (resto) | `//` vira duas divisões seguidas (erro sintático); `%` é erro léxico |

Consequência: como essas palavras não são reservadas nesta versão, elas podem ser usadas como nomes de variáveis (ex.: `cunt = 3` é aceito), ao contrário do que define a seção 2.1 da especificação. Os casos de teste da especificação que dependem desses recursos (V06, M03, M09–M11) não fazem parte da suíte desta entrega.

### O Escopo Otimizado

Ao focar estritamente no núcleo essencial (atribuição, aritméticas, `flash`, `lacrou`/`gag` e `babado`/`turne`), garantimos:

1. Uma gramática limpa, livre de ambiguidades sintáticas desnecessárias.
2. Um Front-end altamente robusto, capaz de validar com precisão blocos indentados e rejeitar erros léxicos e sintáticos.
3. Uma base sólida e organizada para a transição tranquila para a etapa de Back-end (M3).

---

## 4. Guia Passo a Passo para Executar (Do Zero ao Código Rodando)

Se você nunca teve contato com Compiladores ou ferramentas de terminal antes, siga rigorosamente o passo a passo abaixo para rodar o projeto no Windows usando o **WSL (Windows Subsystem for Linux)**.

### Passo 1: Instalar e Abrir o Terminal com WSL (Windows)

Caso ainda não tenha o WSL instalado no seu Windows:

1. Aperte a tecla **Windows**, digite **PowerShell**, clique com o botão direito e escolha **Executar como administrador**.
2. Digite o comando abaixo e aperte Enter para instalar o Linux no Windows:

   ```bash
   wsl --install
   ```

   *(Reinicie o computador se o Windows solicitar).*

Para abrir o terminal e entrar no ambiente Linux sempre que for rodar o projeto:

1. Aperte a tecla **Windows**, digite **Terminal** (ou **Ubuntu**) e abra o aplicativo.
2. Se abrir no PowerShell, digite o comando abaixo e aperte Enter:

   ```bash
   wsl
   ```

   *(O visual do terminal vai mudar mostrando o nome do seu usuário Linux).*

### Passo 2: Instalar as Ferramentas de Compilação (GCC, Flex, Bison e Make)

Com o terminal em WSL aberto, cole o comando abaixo e aperte Enter para instalar tudo o que o compilador precisa para funcionar:

```bash
sudo apt update && sudo apt install -y build-essential flex bison make
```

*(Se ele pedir a sua senha do Linux, digite-a e aperte Enter — os caracteres não aparecem na tela enquanto você digita por segurança).*

> O projeto requer **Bison 3.6 ou superior** (confira com `bison --version`). As versões atuais do Ubuntu no WSL (22.04 e 24.04) já instalam a 3.8.

### Passo 3: Baixar e Entrar na Pasta do Projeto

1. Certifique-se de que os arquivos do projeto estão na sua máquina.
2. No terminal WSL, navegue até a pasta onde estão os arquivos (`lexer.l`, `parser.y`, `main.c`, `Makefile`). No WSL, o disco `C:` do Windows fica dentro de `/mnt/c/`. Por exemplo:
   ```bash
   cd /mnt/c/Users/SeuUsuario/Caminho/Ate/A/Pasta/Do/Projeto
   ```

### Passo 4: Compilar e Executar o Código

Dentro da pasta do projeto, execute os comandos abaixo na ordem:

1. **Limpar arquivos antigos de compilação (garante que tudo comece limpo):**

   ```bash
   make clean
   ```
2. **Compilar o analisador léxico e sintático (gera o executável `divalang`):**

   ```bash
   make
   ```

3. **Rodar o programa de exemplo:**

   ```bash
   make exemplo
   ```

   *Ou, se preferir rodar o executável manualmente passando qualquer arquivo `.diva`:*

   ```bash
   ./divalang testes/validos/exemplo_enxuto.diva
   ```

   Se tudo estiver correto, a mensagem abaixo aparecerá no seu terminal:

   ```text
   Iniciando analise lexica e sintatica de 'testes/validos/exemplo_enxuto.diva'...
   Sucesso! O programa DivaLang esta sintaticamente correto.
   ```
4. **Rodar a suíte de testes completa:**

   ```bash
   make test
   ```

   Ao final aparece um resumo como `120/120 verificacoes passaram`. Veja a seção 5.

### Observação: finais de linha (LF × CRLF)

O Windows termina as linhas com `\r\n` (CRLF) e o Linux com `\n` (LF). O analisador léxico aceita os dois formatos, então arquivos `.diva` salvos em qualquer editor funcionam. Mesmo assim, o repositório possui um `.gitattributes` que mantém todos os arquivos de texto em LF, independente da configuração `core.autocrlf` de cada integrante — não é necessário configurar nada manualmente no Git.

---

## 5. Testes Automatizados

A pasta `testes/` contém casos baseados na seção 6 da especificação (V, L, S e M) e casos de regressão próprios (prefixo `R_`):

```text
testes/
  validos/                 programas que devem ser ACEITOS
  invalidos/lexicos/       programas que devem falhar com erro léxico
  invalidos/sintaticos/    programas que devem falhar com erro sintático
  rodar_testes.sh          executor da suíte (chamado por `make test`)
```

* Cada arquivo inválido declara, na segunda linha, o erro esperado. O teste passa se o analisador rejeitar o programa **e** a mensagem contiver esse texto (incluindo o número da linha):

  ```text
  # L01 - Caractere invalido
  # ESPERADO: Erro lexico na linha 3: caractere invalido ('@')
  fama = 10 @ 2
  ```
* Todo caso roda duas vezes: com o arquivo original (LF) e com uma cópia convertida para CRLF (Windows).
* As mensagens de erro sintático informam também o que o analisador esperava encontrar (quando há até 6 opções), o que facilita corrigir o programa:

  ```text
  Erro sintatico na linha 3 (proximo a ')'): esperado identificador, numero inteiro, numero real, texto, '-' ou '('
  ```

  O `# ESPERADO:` dos testes pode conter só o início da mensagem (até o trecho entre parênteses).
* Os casos `M01`–`M08` são **erros semânticos** da especificação. Como esta entrega não tem ações semânticas, eles são sintaticamente válidos e ficam em `validos/`. Na M3 devem passar a esperar o erro semântico.
* Casos da especificação que usam recursos fora do escopo reduzido (`hit`, `old`, `real` etc. — V06, M03, M09–M11) não foram incluídos.

**Para adicionar um teste**, basta criar um `.diva` na pasta correspondente; para inválidos, inclua a linha `# ESPERADO: <trecho da mensagem>`. Para conferir a mensagem real de um caso, rode `./divalang <arquivo>`.
