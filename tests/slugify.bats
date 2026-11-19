#!/usr/bin/env bats

setup() {
    PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    SLUGIFY="$PROJECT_DIR/slugify"
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
    [ "$output" = "slugify 1.0.0" ]
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

@test "rejects positional input together with explicit stdin" {
    run "$SLUGIFY" "Hello" --stdin
    [ "$status" -ne 0 ]
    [[ "$output" == *"do not combine --stdin"* ]]
}
