#!/usr/bin/env bash
#
# slugify - Convert text into a URL-friendly slug.
# Version: 1.0.0
#
set -o nounset
export LC_ALL=C.UTF-8

VERSION="1.0.0"
SEPARATOR="-"
CASE="lower"
REMOVE_NUMBERS=false
REMOVE_STOP_WORDS=false
MAX_LENGTH=0
USE_STDIN=false

usage() {
    cat <<'EOF'
slugify - Convert text into a URL-friendly slug.

Usage:
  slugify [OPTIONS] TEXT
  slugify [OPTIONS] --stdin
  printf '%s\n' "TEXT" | slugify [OPTIONS]

Options:
  -s, --separator CHAR   Word separator: -, _ or . (default: -)
  -u, --uppercase        Convert output to uppercase
  -l, --lowercase        Convert output to lowercase (default)
  -n, --no-numbers       Remove digits
  -w, --stop-words       Remove English stop words
  -m, --max-length N     Maximum output length; 0 means unlimited
  -i, --stdin            Read input from standard input
  -h, --help             Show this help
  -v, --version          Show version

Examples:
  slugify "Hello, World!"
  slugify "Привіт, світе!"
  slugify "The Best Laravel 12 Tutorial" --stop-words --no-numbers
  slugify "A long article title" --separator _ --max-length 18
  printf '%s\n' "Hello World" | slugify
EOF
}

die() {
    printf 'slugify: error: %s\n' "$*" >&2
    exit 2
}

transliterate() {
    local text="$1"
    local from to
    local -a pairs=(
        'а:a' 'б:b' 'в:v' 'г:h' 'ґ:g' 'д:d' 'е:e' 'є:ye'
        'ж:zh' 'з:z' 'и:y' 'і:i' 'ї:yi' 'й:y' 'к:k' 'л:l'
        'м:m' 'н:n' 'о:o' 'п:p' 'р:r' 'с:s' 'т:t' 'у:u'
        'ф:f' 'х:kh' 'ц:ts' 'ч:ch' 'ш:sh' 'щ:shch' 'ь:'
        'ю:yu' 'я:ya'
        'А:A' 'Б:B' 'В:V' 'Г:H' 'Ґ:G' 'Д:D' 'Е:E' 'Є:Ye'
        'Ж:Zh' 'З:Z' 'И:Y' 'І:I' 'Ї:Yi' 'Й:Y' 'К:K' 'Л:L'
        'М:M' 'Н:N' 'О:O' 'П:P' 'Р:R' 'С:S' 'Т:T' 'У:U'
        'Ф:F' 'Х:Kh' 'Ц:Ts' 'Ч:Ch' 'Ш:Sh' 'Щ:Shch' 'Ь:'
        'Ю:Yu' 'Я:Ya'
    )

    for pair in "${pairs[@]}"; do
        from="${pair%%:*}"
        to="${pair#*:}"
        text="${text//"$from"/$to}"
    done

    # Common non-decomposing Latin letters.
    text="${text//ß/ss}"
    text="${text//ẞ/SS}"
    text="${text//æ/ae}"
    text="${text//Æ/AE}"
    text="${text//œ/oe}"
    text="${text//Œ/OE}"
    text="${text//ø/o}"
    text="${text//Ø/O}"
    text="${text//ł/l}"
    text="${text//Ł/L}"
    text="${text//đ/d}"
    text="${text//Đ/D}"
    text="${text//þ/th}"
    text="${text//Þ/TH}"

    if command -v iconv >/dev/null 2>&1; then
        text="$(printf '%s' "$text" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null)" ||
            die "input is not valid UTF-8 or could not be transliterated"
    else
        # Keep ASCII characters if iconv is unavailable; unsupported characters
        # are removed by the normalization step below.
        text="$(printf '%s' "$text" | LC_ALL=C sed 's/[^ -~]/ /g')"
    fi

    printf '%s' "$text"
}

generate_slug() {
    local input="$1"
    local clean word lookup_word candidate slug=""
    local -a words=()
    local -A stop_map=()
    local stop_words=(
        a an the and or but as at by for from in into of on onto
        to with without is are was were be been being this that
        these those it its
    )

    # Expand a small, predictable set of common symbols.
    input="${input//&/ and }"
    input="${input//\$/ dollar }"
    input="${input//€/ euro }"
    input="${input//£/ pound }"
    input="${input//%/ percent }"
    input="${input//+/ plus }"
    input="${input//@/ at }"

    clean="$(transliterate "$input")"

    if [[ "$CASE" == "lower" ]]; then
        clean="${clean,,}"
    else
        clean="${clean^^}"
    fi

    if [[ "$REMOVE_NUMBERS" == true ]]; then
        clean="$(printf '%s' "$clean" | sed -E 's/[0-9]+/ /g')"
    fi

    # Turn punctuation and all non-ASCII-alphanumeric characters into spaces.
    clean="$(printf '%s' "$clean" | sed -E 's/[^a-zA-Z0-9]+/ /g; s/[[:space:]]+/ /g; s/^ | $//g')"

    if [[ "$REMOVE_STOP_WORDS" == true ]]; then
        for word in "${stop_words[@]}"; do
            stop_map["$word"]=1
        done
    fi

    [[ -n "$clean" ]] || {
        printf '\n'
        return 0
    }

    read -r -a words <<< "$clean"

    for word in "${words[@]}"; do
        [[ -n "$word" ]] || continue

        lookup_word="${word,,}"
        if [[ "$REMOVE_STOP_WORDS" == true && -n "${stop_map[$lookup_word]+present}" ]]; then
            continue
        fi

        if [[ -n "$slug" ]]; then
            candidate="${slug}${SEPARATOR}${word}"
        else
            candidate="$word"
        fi

        if (( MAX_LENGTH > 0 && ${#candidate} > MAX_LENGTH )); then
            if [[ -z "$slug" ]]; then
                slug="${word:0:MAX_LENGTH}"
            fi
            break
        fi

        slug="$candidate"
    done

    printf '%s\n' "$slug"
}

main() {
    local input_text=""
    local -a positional=()

    while (($#)); do
        case "$1" in
            -s|--separator)
                (($# >= 2)) || die "missing value for $1"
                SEPARATOR="$2"
                [[ "$SEPARATOR" == "-" || "$SEPARATOR" == "_" || "$SEPARATOR" == "." ]] ||
                    die "separator must be -, _ or ."
                shift 2
                ;;
            -u|--uppercase)
                CASE="upper"
                shift
                ;;
            -l|--lowercase)
                CASE="lower"
                shift
                ;;
            -n|--no-numbers)
                REMOVE_NUMBERS=true
                shift
                ;;
            -w|--stop-words)
                REMOVE_STOP_WORDS=true
                shift
                ;;
            -m|--max-length)
                (($# >= 2)) || die "missing value for $1"
                [[ "$2" =~ ^[0-9]+$ ]] || die "max length must be a non-negative integer"
                MAX_LENGTH=$((10#$2))
                shift 2
                ;;
            -i|--stdin)
                USE_STDIN=true
                shift
                ;;
            -h|--help)
                usage
                return 0
                ;;
            -v|--version)
                printf 'slugify %s\n' "$VERSION"
                return 0
                ;;
            --)
                shift
                while (($#)); do positional+=("$1"); shift; done
                break
                ;;
            -*)
                die "unknown option: $1 (use --help for usage)"
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$USE_STDIN" == true ]]; then
        [[ ${#positional[@]} -eq 0 ]] || die "do not combine --stdin with positional text"
        input_text="$(cat)"
    elif [[ ${#positional[@]} -gt 0 ]]; then
        input_text="${positional[*]}"
    elif [[ ! -t 0 ]]; then
        input_text="$(cat)"
    else
        die "no input provided (use --help for usage)"
    fi

    generate_slug "$input_text"
}

main "$@"
