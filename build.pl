#!/usr/bin/env perl
use exact -conf;
use Bible::OBML;
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::JSON 'to_json';
use Mojo::Util 'slugify';

my $root_dir  = path( conf->get( qw{ config_app root_dir } ) );
my $bible_src = $root_dir->child( conf->get('obml_src') );
my $word_html = $root_dir->child( conf->get('word_html') );
my $obml      = Bible::OBML->new;
my $last      = {};
my $contents  = {};

$word_html->remove_tree;
for my $testament ( conf->get('structure')->@* ) {
    my ($testament_name) = keys %$testament;
    my $testament_src = $bible_src->child($testament_name);
    next unless ( -d $testament_src );

    for my $section ( $testament->{$testament_name}->@* ) {
        my ($section_name) = keys %$section;
        my $section_src = $testament_src->child($section_name);
        next unless ( -d $section_src );
        my $book_srcs = $section_src->list;

        for my $book_name ( $section->{$section_name}->@* ) {
            my $chapters = $book_srcs->grep( sub { /\/$book_name(?:\s\d+)?$/ } );
            if ( $chapters->size ) {
                $chapters->each( sub ( $src_file, $index ) {
                    my $dom = Mojo::DOM->new( $obml->obml( $src_file->slurp )->html );

                    my $reference = $dom->at('obml reference');
                    my $chapter_name = $reference->content;
                    $reference->remove;

                    my ( @footnotes, @crossrefs );

                    my $number = 1;
                    $dom->find('obml footnote')->each( sub ( $node, $index ) {
                        push( @footnotes, [ $number, $node->content ] );
                        $node->replace(
                            '<footnote>[<a href="#footnote_' . $number . '">' . $number . '</a>]</footnote>'
                        );
                        $number++;
                    } );

                    my $letter = 'A';
                    $dom->find('obml crossref')->each( sub ( $node, $index ) {
                        push( @crossrefs, [ $letter, $node->content ] );
                        $node->replace(
                            '<crossref>(<a href="#crossref_' . $letter . '">' . $letter . '</a>)</crossref>'
                        );
                        $letter++;
                    } );

                    if (@footnotes) {
                        $dom->append_content(
                            '<div class="footnotes"><b>Footnotes</b><ul>' .
                                join( "\n", map {
                                    '<li><a name="footnote_' . $_->[0] . '">' . $_->[0] . '</a> ' .
                                        $_->[1] . '</li>'
                                } @footnotes ) .
                            '</ul></div>'
                        );
                    }

                    if (@crossrefs) {
                        $dom->append_content(
                            '<div class="crossrefs"><b>Cross-References</b><ul>' .
                                join( "\n", map {
                                    '<li><a name="crossref_' . $_->[0] . '">' . $_->[0] . '</a> ' .
                                        $_->[1] . '</li>'
                                } @crossrefs ) .
                            '</ul></div>'
                        );
                    }

                    $dom->find('obml i')->each( sub { $_->tag('italic') } );

                    my $html_file = $word_html->child(
                        join( '/', map { slugify $_ } $src_file->to_rel($bible_src)->to_array->@* ) . '.html'
                    );
                    $html_file->dirname->make_path;
                    $html_file->spew( join( '',
                        qq{<!--#set var="title" value="Was God: $chapter_name"}, "\n",
                        '--><!--#set var="obml_src" value="', $src_file->to_rel($bible_src), '"', "\n",
                        '--><!--#include virtual="/includes/header.html" -->', "\n\n",
                        $dom, "\n\n",
                        '<!--#include virtual="/includes/obml_src.html" -->', "\n",
                        '<!--#include virtual="/includes/footer.html" -->', "\n",
                    ) );
                } );

                if ( not $last->{testament} or $last->{testament} and $last->{testament} ne $testament_name ) {
                    push( @{ $contents->{testaments} }, { name => $testament_name } );
                    $last->{testament} = $testament_name;
                }
                if ( not $last->{section} or $last->{section} and $last->{section} ne $section_name ) {
                    push( @{ $contents->{testaments}[-1]{sections} }, { name => $section_name } );
                    $last->{section} = $section_name;
                }
                push( @{ $contents->{testaments}[-1]{sections}[-1]{books} }, {
                    name           => $book_name,
                    maybe chapters => (
                        ( $book_srcs->grep( sub { /\/$book_name\s\d+?$/ } )->size )
                            ? $chapters->size
                            : undef
                    ),
                } );
                $last->{book} = $book_name;
            }
        }
    }
}

$root_dir->child( conf->get('contents') )->spew( to_json $contents );
