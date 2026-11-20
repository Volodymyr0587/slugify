#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    SLUGIFY="$PROJECT_DIR/slugify"

    TEST_DIR="$BATS_TEST_TMPDIR"
    INPUT_FILE="$TEST_DIR/photo-titles.txt"
    OUTPUT_FILE="$TEST_DIR/photo-slugs.txt"
}

@test "script passes Bash syntax validation" {
    run bash -n "$SLUGIFY"
    [ "$status" -eq 0 ]
}

@test "prints help" {
    run "$SLUGIFY" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "prints version" {
    run "$SLUGIFY" --version
    [ "$status" -eq 0 ]
    [ "$output" = "slugify 1.1.0" ]
}

@test "converts basic English text" {
    run "$SLUGIFY" "Hello, World!"
    [ "$status" -eq 0 ]
    [ "$output" = "hello-world" ]
}

@test "converts Ukrainian text using the project's transliteration map" {
    run "$SLUGIFY" "Привіт, світе!"
    [ "$status" -eq 0 ]
    [ "$output" = "pryvit-svite" ]
}

@test "supports underscore separator" {
    run "$SLUGIFY" "Hello World" --separator _
    [ "$status" -eq 0 ]
    [ "$output" = "hello_world" ]
}

@test "supports dot separator" {
    run "$SLUGIFY" "Hello World" --separator .
    [ "$status" -eq 0 ]
    [ "$output" = "hello.world" ]
}

@test "supports uppercase output" {
    run "$SLUGIFY" "Hello World" --uppercase
    [ "$status" -eq 0 ]
    [ "$output" = "HELLO-WORLD" ]
}

@test "removes numbers" {
    run "$SLUGIFY" "Laravel 12 for Beginners" --no-numbers
    [ "$status" -eq 0 ]
    [ "$output" = "laravel-for-beginners" ]
}

@test "removes English stop words" {
    run "$SLUGIFY" "The Best Way to Learn Bash" --stop-words
    [ "$status" -eq 0 ]
    [ "$output" = "best-way-learn-bash" ]
}

@test "limits length without leaving a trailing separator" {
    run "$SLUGIFY" "how to build a website" --max-length 13
    [ "$status" -eq 0 ]
    [ "$output" = "how-to-build" ]
}

@test "truncates a first word longer than the maximum length" {
    run "$SLUGIFY" "extraordinary title" --max-length 5
    [ "$status" -eq 0 ]
    [ "$output" = "extra" ]
}

@test "zero maximum length means unlimited" {
    run "$SLUGIFY" "Hello World" --max-length 0
    [ "$status" -eq 0 ]
    [ "$output" = "hello-world" ]
}

@test "normalizes repeated punctuation and whitespace" {
    run "$SLUGIFY" "  Hello___,   world!!!  "
    [ "$status" -eq 0 ]
    [ "$output" = "hello-world" ]
}

@test "expands supported symbols" {
    run "$SLUGIFY" "Cats & Dogs + 50%"
    [ "$status" -eq 0 ]
    [ "$output" = "cats-and-dogs-plus-50-percent" ]
}

@test "reads input from a pipe" {
    run bash -c 'printf "%s" "Hello from stdin" | "$1"' _ "$SLUGIFY"
    [ "$status" -eq 0 ]
    [ "$output" = "hello-from-stdin" ]
}

@test "reads input with explicit stdin option" {
    run bash -c 'printf "%s" "Hello from stdin" | "$1" --stdin' _ "$SLUGIFY"
    [ "$status" -eq 0 ]
    [ "$output" = "hello-from-stdin" ]
}

@test "combines multiple options" {
    run "$SLUGIFY" "The Laravel 12 Guide" --separator _ --stop-words --no-numbers --uppercase
    [ "$status" -eq 0 ]
    [ "$output" = "LARAVEL_GUIDE" ]
}

# --------------------------------------------------
# File input tests
# --------------------------------------------------

@test "processes multiple lines from a file" {
    cat > "$INPUT_FILE" <<'EOF'
My Summer Vacation 2026
Beautiful Sunset in Ukraine
Hello World!
EOF

    run "$SLUGIFY" --file "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[0]}" = "my-summer-vacation-2026" ]
    [ "${lines[1]}" = "beautiful-sunset-in-ukraine" ]
    [ "${lines[2]}" = "hello-world" ]
}

@test "supports short file option" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" -f "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "hello-world" ]
}

@test "transliterates Ukrainian text in file input" {
    printf '%s\n' "Привіт, світе!" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "pryvit-svite" ]
}

@test "skips empty lines in file input" {
    cat > "$INPUT_FILE" <<'EOF'
Hello World

Beautiful Sunset

My Favorite Photos
EOF

    run "$SLUGIFY" --file "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[0]}" = "hello-world" ]
    [ "${lines[1]}" = "beautiful-sunset" ]
    [ "${lines[2]}" = "my-favorite-photos" ]
}

@test "processes a file with only empty lines" {
    printf '\n\n\n' > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "processes the final line without a trailing newline" {
    printf '%s' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "hello-world" ]
}

@test "preserves spaces inside individual lines" {
    printf '%s\n' "  Hello   Beautiful World  " > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "hello-beautiful-world" ]
}

@test "supports file input with uppercase option" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --uppercase

    [ "$status" -eq 0 ]
    [ "$output" = "HELLO-WORLD" ]
}

@test "supports file input with no-numbers option" {
    printf '%s\n' "Laravel 12 Tutorial" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --no-numbers

    [ "$status" -eq 0 ]
    [ "$output" = "laravel-tutorial" ]
}

@test "supports file input with stop-words option" {
    printf '%s\n' "The Best Way to Learn Bash" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --stop-words

    [ "$status" -eq 0 ]
    [ "$output" = "best-way-learn-bash" ]
}

@test "supports file input with custom separator" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --separator _

    [ "$status" -eq 0 ]
    [ "$output" = "hello_world" ]
}

@test "supports file input with maximum length" {
    printf '%s\n' "how to build a website" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --max-length 13

    [ "$status" -eq 0 ]
    [ "$output" = "how-to-build" ]
}

@test "supports multiple options with file input" {
    printf '%s\n' "The Laravel 12 Guide" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" \
        --separator _ \
        --stop-words \
        --no-numbers \
        --uppercase

    [ "$status" -eq 0 ]
    [ "$output" = "LARAVEL_GUIDE" ]
}

@test "supports file input with output file" {
    cat > "$INPUT_FILE" <<'EOF'
Hello World
Beautiful Sunset
EOF

    run "$SLUGIFY" --file "$INPUT_FILE" --output "$OUTPUT_FILE"

    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_FILE" ]

    run cat "$OUTPUT_FILE"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "hello-world" ]
    [ "${lines[1]}" = "beautiful-sunset" ]
}

@test "supports short output option" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" -f "$INPUT_FILE" -o "$OUTPUT_FILE"

    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_FILE" ]

    run cat "$OUTPUT_FILE"
    [ "$output" = "hello-world" ]
}

@test "overwrites an existing output file" {
    printf '%s\n' "Old content" > "$OUTPUT_FILE"
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --output "$OUTPUT_FILE"

    [ "$status" -eq 0 ]

    run cat "$OUTPUT_FILE"
    [ "$output" = "hello-world" ]
}

@test "creates output file when it does not exist" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --output "$OUTPUT_FILE"

    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_FILE" ]
    [ "$(cat "$OUTPUT_FILE")" = "hello-world" ]
}

@test "supports output file with multiple options" {
    printf '%s\n' "The Laravel 12 Guide" > "$INPUT_FILE"

    run "$SLUGIFY" \
        --file "$INPUT_FILE" \
        --output "$OUTPUT_FILE" \
        --stop-words \
        --no-numbers \
        --uppercase

    [ "$status" -eq 0 ]
    [ "$(cat "$OUTPUT_FILE")" = "LARAVEL-GUIDE" ]
}

@test "supports output file with ordinary positional input" {
    run "$SLUGIFY" "Hello World" --output "$OUTPUT_FILE"

    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_FILE" ]
    [ "$(cat "$OUTPUT_FILE")" = "hello-world" ]
}

@test "supports output file with stdin input" {
    run bash -c 'printf "%s" "Hello from stdin" | "$1" --stdin --output "$2"' \
        _ "$SLUGIFY" "$OUTPUT_FILE"

    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_FILE" ]
    [ "$(cat "$OUTPUT_FILE")" = "hello-from-stdin" ]
}

# --------------------------------------------------
# File input validation
# --------------------------------------------------

@test "rejects a missing input file" {
    run "$SLUGIFY" --file "$TEST_DIR/missing.txt"

    [ "$status" -ne 0 ]
    [[ "$output" == *"input file does not exist"* ]]
}

@test "rejects a directory as input file" {
    run "$SLUGIFY" --file "$TEST_DIR"

    [ "$status" -ne 0 ]
    [[ "$output" == *"input file does not exist"* ]]
}

@test "rejects missing file argument" {
    run "$SLUGIFY" --file

    [ "$status" -ne 0 ]
    [[ "$output" == *"missing value"* ]]
}

@test "rejects duplicate file options" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --file "$INPUT_FILE"

    [ "$status" -ne 0 ]
    [[ "$output" == *"--file specified more than once"* ]]
}

@test "rejects file input together with explicit stdin" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --stdin

    [ "$status" -ne 0 ]
    [[ "$output" == *"do not combine --file with --stdin"* ]]
}

@test "rejects file input together with positional text" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" "Another text"

    [ "$status" -ne 0 ]
    [[ "$output" == *"do not combine --file with positional text"* ]]
}

@test "rejects missing output argument" {
    run "$SLUGIFY" --file "$INPUT_FILE" --output

    [ "$status" -ne 0 ]
    [[ "$output" == *"missing value"* ]]
}

@test "rejects duplicate output options" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" \
        --output "$OUTPUT_FILE" \
        --output "$TEST_DIR/another.txt"

    [ "$status" -ne 0 ]
    [[ "$output" == *"--output specified more than once"* ]]
}

@test "rejects identical input and output files" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" --file "$INPUT_FILE" --output "$INPUT_FILE"

    [ "$status" -ne 0 ]
    [[ "$output" == *"input and output files must be different"* ]]

    # Original input must remain unchanged.
    [ "$(cat "$INPUT_FILE")" = "Hello World" ]
}

@test "rejects input and output paths pointing to the same file" {
    printf '%s\n' "Hello World" > "$INPUT_FILE"

    run "$SLUGIFY" \
        --file "$INPUT_FILE" \
        --output "$TEST_DIR/./photo-titles.txt"

    [ "$status" -ne 0 ]
    [[ "$output" == *"input and output files must be different"* ]]
}

@test "rejects positional input together with explicit stdin" {
    run "$SLUGIFY" "Hello" --stdin

    [ "$status" -ne 0 ]
    [[ "$output" == *"do not combine --stdin"* ]]
}

@test "rejects an unsupported separator" {
    run "$SLUGIFY" "Hello World" --separator /

    [ "$status" -ne 0 ]
    [[ "$output" == *"separator must be"* ]]
}

@test "rejects a missing separator value" {
    run "$SLUGIFY" "Hello World" --separator

    [ "$status" -ne 0 ]
    [[ "$output" == *"missing value"* ]]
}

@test "rejects an invalid maximum length" {
    run "$SLUGIFY" "Hello World" --max-length abc

    [ "$status" -ne 0 ]
    [[ "$output" == *"max length must be"* ]]
}

@test "rejects an unknown option" {
    run "$SLUGIFY" "Hello World" --unknown

    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown option"* ]]
}
