# slugify

A lightweight Bash CLI utility that converts text into clean, URL-friendly slugs. It supports Ukrainian transliteration, common accented Latin characters, configurable separators, case conversion, stop-word removal, number removal, maximum length, and standard input.

## Features

- English and Ukrainian text handling.
- Transliteration of Ukrainian Cyrillic characters.
- Best-effort transliteration of accented Latin characters through `iconv`.
- Lowercase output by default, with optional uppercase output.
- `-`, `_`, or `.` separators.
- Optional removal of digits and common English stop words.
- Maximum output length without a trailing separator.
- Input as an argument or through stdin/pipes.
- Batch processing of text files, converting each non-empty line into a separate slug.
- Optional output file support for saving generated slugs instead of printing them to stdout.
- No third-party runtime dependencies beyond standard Ubuntu utilities (`bash`, `sed`, and preferably `iconv`).

## Requirements

- Bash 4.3 or newer.
- `sed`.
- `iconv` (recommended for accented Latin characters; Ukrainian transliteration is handled by the script).

Check your environment:

```bash
bash --version
command -v sed
command -v iconv
```

## Installation

### Option 1: Using `install-bash-script`

This project is designed to work with the `install-bash-script` utility.

Place or clone this repository at `~/Desktop/projects/bash/slugify/` so the installer can discover it, then run:

```bash
install-bash-script slugify
```

The installer should validate the script and install it as:

```text
/usr/local/bin/slugify
```

No preliminary `chmod +x` is required when using the installer described in your Bash utilities project. The installer handles installation permissions.

### Option 2: Manual installation

```bash
chmod +x slugify
sudo install -m 755 slugify /usr/local/bin/slugify
```

Verify:

```bash
command -v slugify
slugify --version
```

## Usage

```text
slugify [OPTIONS] TEXT
slugify [OPTIONS] --stdin
slugify [OPTIONS] --file FILE
slugify [OPTIONS] --file FILE --output FILE
printf '%s\n' "TEXT" | slugify [OPTIONS]
```

### Options

| Option                   | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| `-s`, `--separator CHAR` | Word separator: `-`, `_`, or `.`. Default: `-`.                          |
| `-u`, `--uppercase`      | Convert the slug to uppercase.                                           |
| `-l`, `--lowercase`      | Convert the slug to lowercase (default).                                 |
| `-n`, `--no-numbers`     | Remove digits.                                                           |
| `-w`, `--stop-words`     | Remove common English stop words.                                        |
| `-m`, `--max-length N`   | Maximum slug length. `0` means unlimited.                                |
| `-i`, `--stdin`          | Read input from stdin.                                                   |
| `-f`, `--file FILE`      | Read multiple lines from a file, generating one slug per non-empty line. |
| `-o`, `--output FILE`    | Write generated slugs to a file instead of stdout.                       |
| `-h`, `--help`           | Display help.                                                            |
| `-v`, `--version`        | Display version.                                                         |

### Examples

```bash
slugify "Hello, World!"
# hello-world

slugify "Привіт, світе!"
# pryvit-svite

slugify "Laravel 12: Нові можливості"
# laravel-12-novi-mozhlyvosti

slugify "Hello World" --separator _
# hello_world

slugify "Hello World" --uppercase
# HELLO-WORLD

slugify "Laravel 12 for Beginners" --no-numbers
# laravel-for-beginners

slugify "The Best Way to Learn Bash" --stop-words
# best-way-learn-bash

slugify "A long article title" --max-length 18
# a-long-article

printf '%s\n' "A title from a pipe" | slugify
# a-title-from-a-pipe
```

Options may be placed before or after the text:

```bash
slugify --stop-words --separator _ "The Best Bash Guide"
slugify "The Best Bash Guide" --stop-words --separator _
```

#### File Input

Process multiple titles from a text file:

```bash
slugify --file photo-titles.txt
```

Save generated slugs to another file:

```bash
slugify --file photo-titles.txt --output photo-slugs.txt
```

Short options are also supported:

```bash
slugify -f photo-titles.txt -o photo-slugs.txt
```

Combine file input with other options:

```bash
slugify --file article-titles.txt \
    --output article-slugs.txt \
    --stop-words \
    --no-numbers \
    --separator _
```

Each non-empty line is processed independently. Empty lines are skipped, and the final line is processed even if the file does not end with a newline.

The output file is created if it does not exist and overwritten if it already exists. The input and output files must be different.

### Special Characters in Bash

When passing strings containing special shell characters
such as `$`, `!`, `*`, or `&`, use single quotes to
preserve the original input.

```bash
slugify 'Hello World!$$$'
slugify 'C++ & PHP: 100% fun!'
```

Double quotes allow Bash to expand variables and perform
history expansion in interactive shells.

## Testing

The project uses **Bats (Bash Automated Testing System)**. Tests are kept separate from the production script and exercise the command-line interface as a user would.

### 1. Check whether the test framework is installed

First, check whether `bats` is available:

```bash
command -v bats
bats --version
```

If both commands work, Bats is installed and available in your `PATH`.

If `command -v bats` prints nothing, the framework is missing. On Ubuntu:

```bash
sudo apt update
sudo apt install bats
```

Then verify again:

```bash
command -v bats
bats --version
```

Do not confuse Bats with Bash itself: Bash runs the utility, while Bats provides the test framework and assertions.

### 2. Check the project files and permissions

From the repository root:

```bash
tree -a
```

Expected structure:

```text
slugify/
├── slugify
├── README.md
├── LICENSE
└── tests/
    ├── run-tests.sh
    └── slugify.bats
```

Make the test runner executable:

```bash
chmod +x tests/run-tests.sh
```

The main `slugify` file is invoked directly by the tests. It should also be executable in the repository:

```bash
chmod +x slugify
```

### 3. Run static syntax validation

Before executing behavioral tests, ask Bash to parse the production script and the test runner:

```bash
bash -n slugify
bash -n tests/run-tests.sh
```

No output and exit status `0` means the syntax is valid.

You can check the status explicitly:

```bash
bash -n slugify && echo "slugify syntax: OK"
bash -n tests/run-tests.sh && echo "test runner syntax: OK"
```

### 4. Run the complete test suite

Use the project's test runner:

```bash
./tests/run-tests.sh
```

The runner first checks whether Bats exists. If it is missing, it prints installation instructions and exits with status `127`. If Bats is available, the runner performs a Bash syntax check and then starts the Bats suite.

You can also invoke Bats directly:

```bash
bats tests/slugify.bats
```

### 5. Understand what is being tested

The suite covers:

- **CLI basics:** help, version, ordinary text.
- **Transliteration:** Ukrainian input.
- **Formatting:** lowercase, uppercase, and all supported separators.
- **Filtering:** removal of digits and English stop words.
- **Length handling:** unlimited length, word-boundary truncation, and truncation of a first word longer than the limit.
- **Normalization:** repeated punctuation and whitespace.
- **Symbols:** expansion of `&`, `+`, and `%`.
- **Input sources:** positional arguments, pipes, explicit `--stdin`, and file input through `--file`.
- **File processing:** multiple lines, empty lines, missing trailing newline, Ukrainian transliteration, and option combinations.
- **Output handling:** stdout, output files, overwriting existing files, and combined input/output options.
- **Option combinations:** multiple options in one invocation.
- **Error handling:** invalid separator, missing option values, invalid maximum length, unknown options, and conflicting input modes.
- **Syntax:** Bash parser validation.

### 6. Run a focused test

Bats supports filtering tests by name:

```bash
bats --filter "Ukrainian" tests/slugify.bats
bats --filter "separator" tests/slugify.bats
bats --filter "stdin" tests/slugify.bats
bats --filter "file input" tests/slugify.bats
bats --filter "output file" tests/slugify.bats
```

This is useful while developing one feature. After a focused test passes, always run the complete suite.

### 7. Check the exit status

Immediately after running the suite:

```bash
./tests/run-tests.sh
echo "Exit code: $?"
```

An exit code of `0` means all tests passed. A non-zero exit code means the suite failed or could not run. Read the first failed test and its output, fix the implementation or test expectation, and run the suite again.

For shell automation, use:

```bash
if ./tests/run-tests.sh; then
    echo "All tests passed."
else
    echo "Tests failed."
    exit 1
fi
```

### 8. Final test before installation or release

Before installing or tagging a release, run the complete verification sequence from the repository root:

```bash
set -e

echo "1/4: Checking production script syntax..."
bash -n slugify

echo "2/4: Checking test runner syntax..."
bash -n tests/run-tests.sh

echo "3/4: Checking test framework..."
command -v bats
bats --version

echo "4/4: Running all tests..."
./tests/run-tests.sh

echo "All checks passed. Ready to install or release."
```

Only proceed when the command finishes successfully. This is the final project acceptance test: it verifies the Bash syntax, confirms that the test framework is available, and runs every automated test.

## Uninstallation

```bash
sudo rm -- /usr/local/bin/slugify
```

## Limitations

- The stop-word list currently covers common English words only.
- Ukrainian transliteration follows the mapping embedded in this project and is not intended to implement every national or academic transliteration standard.
- Other Cyrillic alphabets are not guaranteed to transliterate correctly.
- Accented Latin transliteration depends on the system's `iconv` implementation and locale.
- Maximum length counts the final ASCII slug characters, including separators.

## License

MIT. See [LICENSE](LICENSE).
