use strict;
use warnings;

package Math::Polygon::Calc;
use vars '$VERSION';
$VERSION = '0.001';
use base 'Exporter';

our @EXPORT = qw/
 polygon_area
 polygon_bbox
 polygon_beautify
 polygon_equal
 polygon_is_clockwise
 polygon_perimeter
 polygon_same
 polygon_start_minxy
 polygon_string
/;

use List::Util    qw/min max/;


sub polygon_string(@) { join ', ', map { "[$_->[0],$_->[1]]" } @_ }


sub polygon_bbox(@)
{
    ( min( map {$_->[0]} @_ )
    , min( map {$_->[1]} @_ )
    , max( map {$_->[0]} @_ )
    , max( map {$_->[1]} @_ )
    );
}


sub polygon_area(@)
{   my $area    = 0;
    while(@_ >= 2)
    {   $area += $_[0][0]*$_[1][1] - $_[0][1]*$_[1][0];
        shift;
    }

    abs($area)/2;
}


sub polygon_is_clockwise(@)
{   my $area  = 0;
    while(@_ >= 2)
    {   $area += $_[0][0]*$_[1][1] - $_[0][1]*$_[1][0];
        shift;
    }

    $area < 0;
}


sub polygon_perimeter(@)
{   my $l    = 0;

    while(@_ >= 2)
    {   $l += sqrt(($_[0][0]-$_[1][0])**2 + ($_[0][1]-$_[1][1])**2);
        shift;
    }

    $l;
}


sub polygon_start_minxy(@)
{   my $minxy = pop @_;    # last==first, remove it
    return $minxy unless @_;
    my $rot   = 0;
    my @res   = @_;

    for(my $i=1; $i<@res; $i++)
    {   if(   $res[$i][0] < $minxy->[0]
	   || ($res[$i][0]==$minxy->[0] && $res[$i][1] < $minxy->[1])
	  )
	{   $minxy = $res[$i];
	    $rot   = $i;
	}
    }

    my @rot = splice @res, 0, $rot;
    (@res, @rot, $minxy);
}


sub polygon_beautify(@)
{   return () unless @_;
    my %opts     = ref $_[0] eq 'HASH' ? %{ (shift) } : ();
    my $despike  = exists $opts{remove_spikes}  ? $opts{remove_spikes}  : 0;
#   my $interpol = exists $opts{remove_between} ? $opts{remove_between} : 0;

    my @res      = @_;
    return () if @res < 4;  # closed triangle = 4 points
    pop @res;               # cyclic: last is first
    my $unchanged= 0;

    while($unchanged < 2*@res)
    {    return () if @res < 3;  # closed triangle = 4 points

         my $this = shift @res;
	 push @res, $this;         # recycle
	 $unchanged++;

         # remove doubles
	 my ($x, $y) = @$this;
         while(@_ && $res[0][0]==$x && $res[0][1]==$y)
	 {   $unchanged = 0;
             shift @res;
	 }

         # remove spike
	 if($despike && @res >= 2)
	 {   # any spike
	     if($res[1][0]==$x && $res[1][1]==$y)
	     {   $unchanged = 0;
	         shift @res;
	     }

	     # x-spike
	     if(   $y==$res[0][1] && $y==$res[1][1]
	        && (  ($res[0][0] < $x && $x < $res[1][0])
	           || ($res[0][0] > $x && $x > $res[1][0])))
	     {   $unchanged = 0;
	         shift @res;
             }

             # y-spike
	     if(   $x==$res[0][0] && $x==$res[1][0]
	        && (  ($res[0][1] < $y && $y < $res[1][1])
	           || ($res[0][1] > $y && $y > $res[1][1])))
	     {   $unchanged = 0;
	         shift @res;
             }
	 }

	 # remove intermediate
	 if(   @res >= 2
	    && $res[0][0]==$x && $res[1][0]==$x
	    && (   ($y < $res[0][1] && $res[0][1] < $res[1][1])
	        || ($y > $res[0][1] && $res[0][1] > $res[1][1])))
	 {   $unchanged = 0;
	     shift @res;
	 }

	 if(   @res >= 2
	    && $res[0][1]==$y && $res[1][1]==$y
	    && (   ($x < $res[0][0] && $res[0][0] < $res[1][0])
	        || ($x > $res[0][0] && $res[0][0] > $res[1][0])))
	 {   $unchanged = 0;
	     shift @res;
	 }

	 # remove 2 out-of order between two which stay
	 if(@res >= 3
	    && $x==$res[0][0] && $x==$res[1][0] && $x==$res[2][0]
	    && ($y < $res[0][1] && $y < $res[1][1]
	        && $res[0][1] < $res[2][1] && $res[1][1] < $res[2][1]))
         {   $unchanged = 0;
	     splice @res, 0, 2;
	 }

	 if(@res >= 3
	    && $y==$res[0][1] && $y==$res[1][1] && $y==$res[2][1]
	    && ($x < $res[0][0] && $x < $res[1][0]
	        && $res[0][0] < $res[2][0] && $res[1][0] < $res[2][0]))
         {   $unchanged = 0;
	     splice @res, 0, 2;
	 }
    }

    @res, $res[0];
}


sub polygon_equal($$;$)
{   my  ($f,$s, $tolerance) = @_;
    return 0 if @$f != @$s;
    my @f = @$f;
    my @s = @$s;

    if(defined $tolerance)
    {    while(@f)
         {    return 0 if abs($f[0][0]-$s[0][0]) > $tolerance
                       || abs($f[0][1]-$s[0][1]) > $tolerance;
              shift @f; shift @s;
         }
         return 1;
    }

    while(@f)
    {    return 0 if $f[0][0] != $s[0][0] || $f[0][1] != $s[0][1];
         shift @f; shift @s;
    }

    1;
}


sub polygon_same($$;$)
{   return 0 if @{$_[0]} != @{$_[1]};
    my @f = polygon_start_minxy @{ (shift) };
    my @s = polygon_start_minxy @{ (shift) };
    polygon_equal \@f, \@s, @_;
}

1;
