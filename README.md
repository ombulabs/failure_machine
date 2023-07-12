# FailureMachine

So you want to know what are your most common failures in RSpec? Pass them trough the Failure Machine.

The idea behind the app is to merely grab json output from RSpec, group together failures with the same root cause
and rank them from most frequent to least frequent.

This is currently in early stages, so the output is pretty limited, it's algorithm for grouping errors together is
the most basic there can be, and it's not thoroughly tested, automatically or otherwise.

In summary, this is a work in progress.

## Installation

For now, the only way to use this is to clone this repo, run `mix install` and then `mix escript.build`

## Usage

The way this works is the following:

```bash
$ ./failure_machine --info [RSPEC LOG OUTPUT FILE]
```

if you have multiple files, like what you get from a CI run, the program accepts globbing:

```bash
$ ./failure_machine --info="name_of_files_glob_*.json"
```

Aditionally, you have 2 other options: `--limi` and `--by-file`.

With `--limit` you can say how much output you want to see, by saying:

```bash
$ ./failure_machine --info="name_of_files_glob_*.json" --limit 10
```

And you can classify the output by file rather than by failure. Useful if you want to have more of an idea of where are most failures rather than what are most failures:

```bash
$ ./failure_machine --info="name_of_files_glob_*.json" --by-file
```

## Testing

We currently have no automated testing, so feel free to contribute.

We have just a test file from a failed run in the rspec repo. It's also not ideal since we're not covering cases involving larger files and other error types, but it's good enough for sanity checks.

Adding automated tests is the next priority, so stay tuned. If you have any ideas for testing automation or even json output files
to add to increase the number of cases we cover, also, feel free to open a PR.

To test, simply install the package and run it against the test data in the `test_data` folder and that's it.
