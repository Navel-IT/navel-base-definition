# Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-base-definition is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::Base::Definition 0.1;

use Navel::Base;

use JSON::Validator;

use Navel::Utils qw/
    clone
    croak
    try_require_namespace
/;

#-> methods

sub _prepare_definition {
    my ($class, $swagger_loader_class, $swagger_definition_path) = @_;

    my $error = try_require_namespace($swagger_loader_class);

    croak($error) if $error;

    no strict 'refs';

    $class = ref $class || $class;

    *{$class . '::swagger_definition'} = sub {
        state $definition = $swagger_loader_class->new()->expand()->api_spec()->get($swagger_definition_path);
    };
}

sub _create_setters {
    my $class = shift;

    no strict 'refs';

    $class = ref $class || $class;

    for my $property (@_) {
        *{$class . '::set_' . $property} = sub {
            shift->SUPER::merge(
                {
                    $property => shift
                }
            );
        };
    }
}

sub properties {
    return {
        %{clone(shift)}
    };
}

sub new {
    my ($class, $definition) = @_;

    $definition = properties($definition);

    my $errors = $class->validate($definition);

    die $errors if @{$errors};

    bless $definition, ref $class || $class;
}

sub validate {
    my ($class, %options) = @_;

    my $definition_fullname;

    my @errors = JSON::Validator->new()->schema($options{validator})->validate($options{raw_definition});

    push @errors, @{$options{code_validator}->()} if ref $options{code_validator} eq 'CODE';

    if (defined $options{if_possible_suffix_errors_with_key_value}) {
        local $@;

        my $definition_name = eval {
            $options{raw_definition}->{$options{if_possible_suffix_errors_with_key_value}};
        };

        $definition_fullname = $definition_name if defined $definition_name;

        $definition_fullname = $options{definition_class} . '[' . $definition_fullname . ']';
    } else {
        $definition_fullname = $options{definition_class};
    }

    [
        map {
            $definition_fullname . ': ' . (defined $_  ? $_ : '?')
        } @errors
    ];
}

sub persistant_properties {
    my ($properties, $runtime_properties) = (shift->properties(), @_);

    if (ref $runtime_properties eq 'ARRAY') {;
        delete $properties->{$_} for @{$runtime_properties};
    }

    $properties;
}

sub merge {
    my ($self, $hash_to_merge) = @_;

    croak('hash_to_merge must be a HASH reference') unless ref $hash_to_merge eq 'HASH';

    my $errors = $self->validate(
        {
            %{$self->properties()},
            %{$hash_to_merge}
        }
    );

    unless (@{$errors}) {
        $self->{$_} = $hash_to_merge->{$_} for keys %{$hash_to_merge};
    }

    $errors;
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::Base::Definition

=head1 COPYRIGHT

Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-base-definition is licensed under the Apache License, Version 2.0

=cut
