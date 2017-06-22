# AAI

[![Build Status](https://travis-ci.org/mooreryan/aai.svg?branch=master)](https://travis-ci.org/mooreryan/aai)
[![Coverage Status](https://coveralls.io/repos/github/mooreryan/aai/badge.svg?branch=master)](https://coveralls.io/github/mooreryan/aai?branch=master)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Calculate Seanie's multi-genome (or genome bin, or metagenome sample) amino acid similarity.

## Requirements

The following programs must be installed and on your `PATH` for `aai` to work.

- GNU Parallel
- NCBI Blast suite

## Installation

### Install with RubyGems

Run

    $ gem install aai

### If bundling aai in another ruby program

Add this line to your application's Gemfile:

```ruby
gem 'aai'
```

And then execute:

    $ bundle

## Usage

### Example

```
$ ruby exe/aai.rb --infiles *.fa
```

### Options

```
Options:
  -i, --infiles=<s+>    Input files
  -o, --outdir=<s>      Output directory (default: .)
  -b, --basename=<s>    Base name for output file (default: aai_scores)
  -v, --version         Print version and exit
  -h, --help            Show this message
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/aai. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
