# Copyright (C) 2015-2017 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-base-definition is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::Base::Definition::Parser::Writer 0.1;

use Navel::Base;

use AnyEvent::AIO;
use IO::AIO;

use Promises 'deferred';

use Navel::Utils qw/
    json_constructor
    croak
/;

#-> class variables

my $json_constructor = json_constructor->canonical->pretty;

#-> methods

sub async_write {
    my ($self, %options) = @_;

    $self->{file_path} = $options{file_path} if defined $options{file_path};

    croak('file_path must be defined') unless defined $self->{file_path};

    local $!;

    my $deferred = deferred;

    aio_open($self->{file_path}, IO::AIO::O_CREAT | IO::AIO::O_WRONLY, 0666,
        sub {
            my $filehandle = shift;

            if ($filehandle) {
                aio_truncate($filehandle, 0, sub {
                    if (@_) {
                        my $serialized_definitions = $json_constructor->encode($options{definitions});

                        aio_write($filehandle, undef, (length $serialized_definitions), $serialized_definitions, 0,
                            sub {
                                if (shift == length $serialized_definitions) {
                                    $deferred->resolve($self->{file_path});
                                } else {
                                    $deferred->reject($self->{file_path} . ': the definitions have not been properly written, they are probably corrupt');
                                }

                                aio_close($filehandle);
                            }
                        );
                    } else {
                        $deferred->reject($self->{file_path} . ': ' . $!);

                        aio_close($filehandle);
                    }
                });
            } else {
                $deferred->reject($self->{file_path} . ': ' . $!);
            }
        }
    );

    $deferred->promise;
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

Copyright (C) 2015-2017 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-base-definition is licensed under the Apache License, Version 2.0

=cut
