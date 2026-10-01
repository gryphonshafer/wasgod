'use strict';
( () => {
    const src_url  = new URL( document.currentScript.src );
    const version  = src_url.searchParams.get('version');
    const contents = fetch( '/contents.json?version=' + version ).then( response => response.json() );

    function slugify(str) {
        return str
            .normalize('NFD')
            .replace( /[\u0300-\u036f]/g, '' )
            .toLowerCase()
            .trim()
            .replace( /[^\w\s-]/g, '' )
            .replace( /[\s_-]+/g, '-' )
            .replace( /^-+|-+$/g, '' );
    }

    function make_url( testament, section, book ) {
        return '/word/' + [ testament, section, book ].map( element => slugify(element) ).join('/') + '.html';
    }

    async function page_setup() {
        const toc = document.querySelector('toc');
        if (toc) {
            const data    = await contents;
            toc.innerHTML = '<ul class="testaments">' +
                data.testaments.map( testament => {
                    return '<li>' +
                        testament.name +
                        '<ul class="sections">' +
                            testament.sections.map( section => {
                                return '<li>' +
                                    section.name +
                                    '<ul class="books">' +
                                        section.books.map( book => {
                                            if ( book.chapters ) {
                                                return '<li>' +
                                                    book.name +
                                                    '<ul>' +
                                                        [ ...Array( book.chapters ) ].map( ( _, index ) => {
                                                            return '<li>' +
                                                                '<a href="' +
                                                                    make_url(
                                                                        testament.name,
                                                                        section.name,
                                                                        book.name + ' ' + ( index + 1 )
                                                                    ) +
                                                                '">' +
                                                                    '<span>Chapter </span>' +
                                                                    ( index + 1 ) +
                                                                '</a>' +
                                                            '</li>';
                                                        } ).join('') +
                                                    '</ul>' +
                                                '</li>';
                                            }
                                            else {
                                                return '<li>' +
                                                    '<a href="' +
                                                        make_url( testament.name, section.name, book.name ) +
                                                    '">' +
                                                        book.name +
                                                    '</a>' +
                                                '</li>';
                                            }
                                        } ).join('') +
                                    '</ul>' +
                                '</li>';
                            } ).join('') +
                        '</ul>' +
                    '</li>';
                } ).join('') +
            '</ul>';
        }
    }

    if ( document.readyState === 'loading' ) {
        document.addEventListener( 'DOMContentLoaded', page_setup );
    }
    else {
        page_setup();
    }
} )();
