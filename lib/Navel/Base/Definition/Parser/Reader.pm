# Copyright (C) 2015-2017 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-base-definition is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::Base::Definition::Parser::Reader 0.1;

use Navel::Base;

use Navel::Utils qw/
    json_constructor
    croak
    path
/;

#-> class variables

my $json_constructor = json_constructor;

#-> methods

sub read {
    my ($self, %options) = @_;

    $self->{file_path} = $options{file_path} if defined $options{file_path};

    croak('file_path must be defined') unless defined $self->{file_path};

    my $deserialized = eval {
        my $file_content = path($self->{file_path})->slurp;

        die $! if $!;

        $json_constructor->decode($file_content);
    };

    die $self->{file_path} . ': ' . $@ . "\n" if $@;

    $deserialized;
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::Base::Definition::Parser::Reader

=head1 COPYRIGHT

Copyright (C) 2015-2017 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-base-definition is licensed under the Apache License, Version 2.0

=cut
