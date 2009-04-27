package Parse::Deb::Control;

=head1 NAME

Parse::Deb::Control - parse and manipulate F<debian/control> in a controlable way

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Class::Accessor::Fast';

use File::Slurp qw(read_file write_file);
use Storable 'dclone';
use List::MoreUtils 'any';
use IO::String;

=head1 PROPERTIES

=cut

__PACKAGE__->mk_accessors(qw{
    filename
    _control_src
    content
    structure
});

=head1 METHODS

=head2 new()

Object constructor.

=cut

sub new {
    my $class = shift;
    my $src   = shift;
    my $self  = $class->SUPER::new({});
    
    return $self
        if not $src;
    
    # assume it's file handle if it can getline method
    if (eval { $src->can('getline') }) {
        $self->_control_src($src);
        return $self;
    }

    # assume it's string if there are new lines
    if ($src =~ m/\n/xms) {
        $self->_control_src(IO::String->new($src));
        return $self;
    }

    # otherwise open file for reading
    open my $io, '<', $src or die 'failed to open "'.$src.'" - '.$!;
    $self->_control_src($io);

    return $self;
}

sub content {
    my $self = shift;
    my $content = $self->{'content'};

    return $content
        if defined $content;
    
    my @structure   = ();
    my @content     = ();
    my $last_value  = undef;
    my $last_para   = undef;
    my $control_txt = '';
    
    my $line_number = 0;
    my $control_src = $self->_control_src;
    while (my $line = <$control_src>) {
        $line_number++;
        $control_txt .= $line;
        
        # if the line is epmty it's the end of control paragraph
        if ($line =~ /^\s*$/) {
            $last_value = undef;
            push @structure, $line;
            if (defined $last_para) {
                push @content, $last_para;
                $last_para = undef;
            }
            next;
        }
        
        # line starting with white space
        if ($line =~ /^\s/) {
            die 'not previous value to append "'.$line.'" to (line '.$line_number.')'
                if not defined $last_value;
            ${$last_value} .= $line;
            next;
        }
        
        # other should be key/value lines
        if ($line =~ /^([^:]+):(.*$)/xms) {
            my ($key, $value) = ($1, $2);
            push @structure, $key;
            $last_para->{$key} = $value;
            $last_value = \($last_para->{$key});
            next;
        }
        
        die 'unrecognized format "'.$line.'" (line '.$line_number.')';
    }
    push @content, $last_para
        if defined $last_para;
    
    $self->{'content'} = \@content;
    $self->structure(\@structure);

    # for debugging
    # use File::Slurp 'write_file';
    # write_file('xxx1', $control_txt);
    # write_file('xxx2', $self->control);
    
    die 'control reconstruction failed, send your "control" file attached to bug report :)'
        if $control_txt ne $self->_control;
    
    return \@content;
}

sub control {
    my $self = shift;
    
    my $control_txt = $self->_control;
    
    # run through parser again to test if future parsing will be successful
    eval {
        my $parser = Parse::Deb::Control->new($control_txt)->content;
    };
    if ($@) {
        die 'generating and parsing back failed ("'.$@.'"), this is probably a bug. attach your control file and manipulations you did to the bug report :)'
    }
    
    return $control_txt;
}

sub _control {
    my $self = shift;
    
    my $control_txt = '';
    my @content     = @{$self->content};
    my %cur_para    = %{shift @content};
    
    # loop through the control file structure
    foreach my $structure_key (@{$self->structure}) {
        if ($structure_key =~ /^\s*$/) {
            # loop throug new keys and add them
            foreach my $key (sort keys %cur_para) {
                $control_txt .= $key.':'.(delete $cur_para{$key});
            }
            
            # add the space
            $control_txt .= $structure_key;
            
            %cur_para = ();
            next;
        }
        
        # get next paragraph if empty
        %cur_para = %{shift @content}
            if not %cur_para;
        
        my $value = delete $cur_para{$structure_key};
        $control_txt .= $structure_key.':'.$value
            if $value;
    }
    # loop throug new keys and add them
    foreach my $key (sort keys %cur_para) {
        $control_txt .= $key.':'.(delete $cur_para{$key});
    }
    
    return $control_txt;
}

sub get_keys {
    my $self   = shift;
    my @wanted = @_;
    
    my @content = @{$self->content};

    my @wanted_keys;
    foreach my $para (@content) {
        foreach my $key (keys %{$para}) {
            if (any { $_ eq $key } @wanted) {
                push @wanted_keys, {
                    'key'   => $key,
                    'value' => \$para->{$key},
                    'para'  => $para,
                };
            }
        }
    }
    
    return @wanted_keys;
}

1;


__END__

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-deb-control at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Deb-Control>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Deb::Control


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Deb-Control>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Deb-Control>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Deb-Control>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Deb-Control>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Parse::Deb::Control
