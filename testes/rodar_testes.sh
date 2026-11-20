#!/bin/sh
# Suite de testes do front-end DivaLang.
#
# Uso: sh testes/rodar_testes.sh [caminho/do/divalang]
#
#   testes/validos/*.diva             devem ser ACEITOS (codigo de saida 0)
#   testes/invalidos/<tipo>/*.diva    devem ser REJEITADOS e a saida de erro
#                                     deve conter o texto da linha
#                                     "# ESPERADO: <mensagem>" do proprio arquivo
#
# Cada caso roda duas vezes: com o arquivo original (LF) e com uma copia
# convertida para finais de linha CRLF (Windows). A mensagem esperada deve
# ser a mesma nos dois formatos.

BIN=${1:-./divalang}
DIR=$(dirname "$0")

if [ ! -x "$BIN" ]; then
    echo "Executavel '$BIN' nao encontrado. Rode 'make' antes." >&2
    exit 2
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

total=0
falhas=0

# executa <arquivo> -> define $status e grava stderr em $TMP/err
executa() {
    "$BIN" "$1" >/dev/null 2>"$TMP/err" </dev/null
    status=$?
}

# verifica <arquivo> <esperado> -> retorna 0 se o resultado bate
verifica() {
    executa "$1"
    if [ -z "$2" ]; then
        [ "$status" -eq 0 ]
    else
        [ "$status" -ne 0 ] && grep -qF -- "$2" "$TMP/err"
    fi
}

testa() {
    arquivo=$1
    nome=${arquivo#"$DIR"/}
    esperado=""

    case "$nome" in
        invalidos/*)
            esperado=$(sed -n 's/^# ESPERADO: //p' "$arquivo" | head -n 1 | tr -d '\r')
            if [ -z "$esperado" ]; then
                total=$((total + 1)); falhas=$((falhas + 1))
                echo "FALHA  $nome: falta a linha '# ESPERADO: ...'"
                return
            fi
            ;;
    esac

    # Copia com CRLF: troca cada \n por \r\n (sed -z le o arquivo inteiro)
    crlf="$TMP/$(basename "$arquivo")"
    sed -z 's/\n/\r\n/g' "$arquivo" > "$crlf"

    for modo in LF CRLF; do
        total=$((total + 1))
        if [ "$modo" = LF ]; then alvo=$arquivo; else alvo=$crlf; fi

        if verifica "$alvo" "$esperado"; then
            echo "ok     $nome ($modo)"
        else
            falhas=$((falhas + 1))
            echo "FALHA  $nome ($modo)"
            if [ -z "$esperado" ]; then
                echo "         esperado: aceito (saida 0)"
            else
                echo "         esperado: erro contendo \"$esperado\""
            fi
            echo "         obtido:   saida $status; $(head -n 1 "$TMP/err")"
        fi
    done
}

for arquivo in "$DIR"/validos/*.diva "$DIR"/invalidos/*/*.diva; do
    [ -f "$arquivo" ] && testa "$arquivo"
done

echo
echo "$((total - falhas))/$total verificacoes passaram ($((total / 2)) casos x LF/CRLF)."
[ "$falhas" -eq 0 ]
