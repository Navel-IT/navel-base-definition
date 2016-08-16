# Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-base-definition is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::Base::Definition::Parser::Writer 0.1;

use Navel::Base;

use AnyEvent::AIO;
use IO::AIO;

use Navel::Utils qw/
    croak
    encode_yaml
    path
/;

#-> methods

sub write {
    my ($self, %options) = @_;

    $self->{file_path} = $options{file_path} if defined $options{file_path};

    croak('file_path must be defined') unless defined $self->{file_path};

    croak('on_* must be defined') unless ref $options{on_success} eq 'CODE' && ref $options{on_error} eq 'CODE';

    if ($options{async}) {
        local $!;

        aio_open($self->{file_path}, IO::AIO::O_CREAT | IO::AIO::O_WRONLY, 0666,
            sub {
                my $filehandle = shift;

                if ($filehandle) {
                    aio_truncate($filehandle, 0, sub {
                        if (@_) {
                            my $serialized_definitions = encode_yaml($options{definitions});

                            aio_write($filehandle, undef, (length $serialized_definitions), $serialized_definitions, 0,
                                sub {
                                    if (shift == length $serialized_definitions) {
                                        $options{on_success}->($self->{file_path});
                                    } else {
                                        $options{on_error}->($self->{file_path} . ': the definitions have not been properly written, they are probably corrupt');
                                    }

                                    aio_close($filehandle);
                                }
                            );
                        } else {
                            $options{on_error}->($self->{file_path} . ': ' . $!);

                            aio_close($filehandle);
                        }
                    });
                } else {
                    $options{on_error}->($self->{file_path} . ': ' . $!);
                }
            }
        );
    } else {
        local $@;

        eval {
            path($self->{file_path})->spew(
                {
                    truncate => 1
                },
                [
                    encode_yaml($options{definitions})
                ]
            );
        };

        unless ($@) {
            $options{on_success}->($self->{file_path});
        } else {
            $options{on_error}->($self->{file_path} . ': ' . $@);
        }
    }

    $self;
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::Base::Definition::Parser::Writer

=head1 COPYRIGHT

Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-base-definition is licensed under the Apache License, Version 2.0

=cut
