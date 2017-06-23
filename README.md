# AAI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Calculate Seanie's multi-genome (or genome bin, or metagenome sample) amino acid similarity.

## Requirements

The following programs must be installed and on your `PATH` for `aai` to work.

For versions `>= 0.4`

- [DIAMOND](https://github.com/bbuchfink/diamond/)

For versions `< 0.4`

- [NCBI Blast suite](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

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
$ ruby exe/aai.rb --infiles *.fa --outdir aai_output
```

### Options

```
Options:
  -c, --cpus=<i>        Number of CPUs to use (default: 1)
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
