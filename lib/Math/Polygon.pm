use strict;
use warnings;

package Math::Polygon;
use vars '$VERSION';
$VERSION = '0.001';
use Math::Polygon::Calc;
use Math::Polygon::Clip;


sub new(@)
{   my $thing = shift;
    my $class = ref $thing || $thing;

    my @points;
    my %options;
    if(ref $thing)
    {   $options{clockwise} = $thing->{MP_clockwise};
    }

    while(@_)
    {   if(ref $_[0] eq 'ARRAY') {push @points, shift}
        else { my $k = shift; $options{$k} = shift }
    }
    $options{_points} = \@points;

    (bless {}, $class)->init(\%options);
}

sub init($$)
{   my ($self, $args) = @_;
    $self->{MP_points}    = $args->{points} || $args->{_points};
    $self->{MP_clockwise} = $args->{clockwise};
    $self->{MP_bbox}      = $args->{bbox};
    $self;
}


sub nrPoints() { scalar @{shift->{MP_points}} }


sub order() { @{shift->{MP_points}} -1 }


sub points() { wantarray ? @{shift->{MP_points}} : shift->{MP_points} }


sub point(@)
{   my $points = shift->{MP_points};
    wantarray ? @{$points}[@_] : $points->[shift];
}


sub string() { polygon_string shift->points }


sub bbox()
{   my $self = shift;
    return @{$self->{MP_bbox}} if $self->{MP_bbox};

    my @bbox = polygon_bbox $self->points;
    $self->{MP_bbox} = \@bbox;
}


sub area()
{   my $self = shift;
    return $self->{MP_area} if defined $self->{MP_area};
    $self->{MP_area} = polygon_area $self->points;
}


sub isClockwise()
{   my $self = shift;
    return $self->{MP_clockwise} if defined $self->{MP_clockwise};
    $self->{MP_clockwise} = polygon_is_clockwise $self->points;
}


sub perimeter() { polygon_perimeter shift->points }


sub startMinXY()
{   my $self = shift;
    $self->new(polygon_start_minxy $self->points);
}


sub beautify(@)
{   my ($self, %opts) = @_;
    my @beauty = polygon_beautify \%opts, $self->points;
    @beauty>2 ? $self->new(points => \@beauty) : ();
}


sub equal($;@)
{   my $self  = shift;
    my ($other, $tolerance);
    if(@_ > 2 || ref $_[1] eq 'ARRAY') { $other = \@_ }
    else
    {   $other     = ref $_[0] eq 'ARRAY' ? shift : shift->points;
        $tolerance = shift;
    }
    polygon_equal scalar($self->points), $other, $tolerance;
}


sub same($;@)
{   my $self = shift;
    my ($other, $tolerance);
    if(@_ > 2 || ref $_[1] eq 'ARRAY') { $other = \@_ }
    else
    {   $other     = ref $_[0] eq 'ARRAY' ? shift : shift->points;
        $tolerance = shift;
    }
    polygon_same scalar($self->points), $other, $tolerance;
}


sub lineClip($$$$)
{   my ($self, @bbox) = @_;
    polygon_line_clip \@bbox, $self->points;
}


sub fillClip1($$$$)
{   my ($self, @bbox) = @_;
    my @clip = polygon_fill_clip1 \@bbox, $self->points;
    $self->new(points => \@clip);
}

1;
