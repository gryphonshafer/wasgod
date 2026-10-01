#!/usr/bin/env perl
use exact -conf;

say conf->get( qw{ config_app root_dir } );
say conf->get('answer');

# TODO: includes/chapters.html
# TODO: word/...
