package MT::Plugin::OMV::TemplateBuilder;

use strict;
use MT::Util;
use MT::Template;
use MT::Template::Context;
#use Data::Dumper;#DEBUG



MT::Template::Context->add_tag( BuildTemplate  => \&_hdlr_build_template );
sub _hdlr_build_template {
    my( $ctx, $args, $cond ) = @_;

    ### Template to rebuild
    my $tmpl_name = $args->{template}
        or return $ctx->error( MT->translate( "You must set the Template Name." ));
    my $blog = $ctx->stash( 'blog' )
        or return $ctx->error( MT->translate( "Load of blog failed: [_1]", $ctx->stash( 'tag' )));
    my $blog_id = $blog->id;

    ### Loading specified template
    my $tmpl = MT::Template->load({ type => 'index', blog_id => $blog_id, identifier => $tmpl_name })
            || MT::Template->load({ type => 'index', blog_id => $blog_id, name => $tmpl_name })
            || MT::Template->load({ type => 'index', blog_id => $blog_id, outfile => $tmpl_name })
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
        ? "<!-- ". localtime. ' - '. MT::Util::encode_html( $tmpl_name ). ' -->'
        : '' # Empty return
}

1;