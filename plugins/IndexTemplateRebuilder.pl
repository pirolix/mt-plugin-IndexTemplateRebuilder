package MT::Plugin::OMV::IndexTemplateRebuilder;

use strict;
use MT::Blog;
use MT::Util;
use MT::Template;
use MT::Template::Context;
#use Data::Dumper;#DEBUG



MT::Template::Context->add_tag( BuildIndexTemplate  => \&_hdlr_build_index_template );
sub _hdlr_build_index_template {
    my( $ctx, $args, $cond ) = @_;

    ### Template to rebuild
    my $tmpl_name = $args->{name}
        or return $ctx->error( MT->translate( "You must set the Template Name." ));
    my $blog = $ctx->stash( 'blog' );
    if( defined( my $blog_id = $args->{blog_id})) {
        $blog = MT::Blog->load({ id => $blog_id });
    }
    $blog or return $ctx->error( MT->translate( "Load of blog failed: [_1]", $ctx->stash( 'tag' )));

    ### Loading specified template
    my $tmpl = MT::Template->load({ type => 'index', blog_id => $blog->id, identifier => $tmpl_name })
            || MT::Template->load({ type => 'index', blog_id => $blog->id, name => $tmpl_name })
            || MT::Template->load({ type => 'index', blog_id => $blog->id, outfile => $tmpl_name })
        or return $ctx->error( MT->translate( "Can't find template '[_1]'", $tmpl_name ));

    ### Asynchronous rebuild
    if( $args->{async} || $args->{background} ) {
        MT::Util::start_background_task( sub {
            MT->instance->rebuild_indexes( Blog => $blog, Template => $tmpl, Force => 1 )
                or return;
        });
    }
    ### Synchronous
    else {
        MT->instance->rebuild_indexes( Blog => $blog, Template => $tmpl, Force => 1 )
            or return;
    }

    ### My Outputs
    $args->{verbose}
        ? "<!-- ". localtime( time ()). ' - '. MT::Util::encode_html( $tmpl_name ). ' -->'
        : '' # Empty return
}

1;