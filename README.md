# WasGod.org

This is the software, data, and supporting content behind the [WasGod.org](https://wasgod.org) web site.

## Installation

1. Clone this project
2. Clone [Bible](https://github.com/gryphonshafer/Bible) into the `~/site` directory of this project's checkout
3. Run `~/bin/build.pl`
4. In your web server of choice, set `~/site` as the location root and turn on server-side includes

## Content Updates

1. Pull [Bible](https://github.com/gryphonshafer/Bible) from within `~/site/Bible`
2. Rerun `~/bin/build.pl`

## Dependencies

- [Bible](https://github.com/gryphonshafer/Bible)
- [Bible::OBML](https://github.com/gryphonshafer/Bible-OBML)
