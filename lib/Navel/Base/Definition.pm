# Copyright (C) 2015-2016 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-base-definition is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::Base::Definition 0.1;

use Navel::Base;

use Navel::Utils qw/
    clone
    blessed
    croak
/;

#-> methods

sub _create_setters {
    my $class = shift;

    no strict 'refs';

    $class = ref $class || $class;

    for my $property (@_) {
        *{$class . '::set_' . $property} = sub {
            shift->merge(
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
    my $class = shift;

    my $definition = properties(shift);

    my $errors = $class->validate($definition);

    die $errors if @{$errors};

    bless $definition, ref $class || $class;
}

sub validate {
    my ($class, %options) = @_;

    my @errors;

    push @errors, @{$options{validator}->($options{raw_definition})} if ref $options{validator} eq 'CODE';
    
    my $definition_fullname = ref $class || $class;

    if (defined $options{if_possible_suffix_errors_with_key_value}) {
        local $@;

        $definition_fullname .= '[' . (
            eval {
                $options{raw_definition}->{$options{if_possible_suffix_errors_with_key_value}};
            } // ''
        ) . ']';
    }

    [
        map {
            $definition_fullname . ': ' . ($_ // '?')
        } @errors
    ];
}

sub persistant_properties {
    my ($properties, $runtime_properties) = (shift->properties, @_);

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
            %{$self->properties},
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

Copyright (C) 2015-2016 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-base-definition is licensed under the Apache License, Version 2.0

=cut
