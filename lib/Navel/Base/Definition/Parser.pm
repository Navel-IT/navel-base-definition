# Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-base-definition is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::Base::Definition::Parser 0.1;

use Navel::Base;

use parent qw/
    Navel::Base::Definition::Parser::Reader
    Navel::Base::Definition::Parser::Writer
/;

use Navel::Utils qw/
    try_require_namespace
    croak
    isint
/;

#-> methods

sub new {
    my ($class, %options) = @_;

    my $self = bless {
        definition_class => $options{definition_class},
        do_not_need_at_least_one => $options{do_not_need_at_least_one},
        defnitions_validation_on_errors => $options{defnitions_validation_on_errors},
        file_path => undef,
        raw => [],
        definitions => []
    }, ref $class || $class;

    $self->set_maximum($options{maximum});
}

sub read {
    my $self = shift;

    $self->{raw} = $self->SUPER::read(@_);

    $self;
}

sub async_write {
    my $self = shift;

    $self->SUPER::async_write(
        definitions => [
            map {
                $_->persistant_properties()
            } @{$self->{definitions}}
        ],
        @_
    );
}

sub make_definition {
    shift->{definition_class}->new(@_);
};

sub make {
    my ($self, %options) = @_;

    my $load_class_error = try_require_namespace($self->{definition_class});

    croak($load_class_error) if $load_class_error;

    if (ref $self->{raw} eq 'ARRAY' and @{$self->{raw}} || $self->{do_not_need_at_least_one}) {
        my @errors;

        local $@;

        for (@{$self->{raw}}) {
            my $definition_parameters = ref $options{extra_parameters} eq 'HASH'
            ?
                {
                    %{$_},
                    %{$options{extra_parameters}}
                }
            : $_;

            eval {
                $self->make_definition($definition_parameters);
            };

            unless ($@) {
                $self->add_definition($definition_parameters);
            } else {
                push @errors, $@;
            }
        }

        die \@errors if @errors;

        undef $self->{raw};
    } else {
        die $self->{definition_class} . ": definitions must be encapsulated in an array\n";
    }

    $self;
}

sub set_maximum {
    my ($self, $maximum) = @_;

    my $minimum = 0;

    $maximum ||= $minimum;

    die 'maximum must be an integer equal or greater than ' . $minimum . "\n" unless isint($maximum) && $maximum >= $minimum;

    $self->{maximum} = $maximum;

    $self;
}

sub definition_by_name {
    my ($self, $name) = @_;

    croak('name must be defined') unless defined $name;

    for (@{$self->{definitions}}) {
        return $_ if $_->{name} eq $name;
    }

    undef;
}

sub definition_properties_by_name {
    my $definition = shift->definition_by_name(@_);

    defined $definition ? $definition->properties() : undef;
}

sub all_by_property_name {
    my ($self, $name) = @_;

    croak('name must be defined') unless defined $name;

    [
        map {
            $_->can($name) ? $_->$name() : $_->{$name}
        } @{$self->{definitions}}
    ];
}

sub add_definition {
    my ($self, $raw_definition) = @_;

    my $definition = $self->make_definition($raw_definition);

    die $self->{definition_class} . ': the maximum number of definition (' . $self->{maximum} . ") has been reached\n" if $self->{maximum} && @{$self->{definitions}} > $self->{maximum};
    die $self->{definition_class} . ': duplicate definition (' . $definition->full_name() . ") detected\n" if defined $self->definition_by_name($definition->{name});

    push @{$self->{definitions}}, $definition;

    $definition;
}

sub delete_definition {
    my ($self, %options) = @_;

    croak('definition_name must be defined') unless defined $options{definition_name};

    my $finded;

    my $definition_to_delete_index = 0;

    $definition_to_delete_index++ until $finded = $self->{definitions}->[$definition_to_delete_index]->{name} eq $options{definition_name};

    die $self->{definition_class} . ': definition ' . $options{definition_name} . " does not exists\n" unless $finded;

    $options{do_before_slice}->($self->{definitions}->[$definition_to_delete_index]) if ref $options{do_before_slice} eq 'CODE';

    splice @{$self->{definitions}}, $definition_to_delete_index, 1;

    $options{definition_name};
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::Base::Definition::Parser

=head1 COPYRIGHT

Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-base-definition is licensed under the Apache License, Version 2.0

=cut
