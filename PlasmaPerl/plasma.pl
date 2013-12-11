#!/usr/bin/perl



# Textmode Plasma
# Lee Coakley



use strict;
use warnings;





# =============================================================================
# Main program
# =============================================================================

&plasma();





# =============================================================================
# Subroutines
# =============================================================================

# plasma()
# Draws some flowy shapes using a mordibly awful textmode rendering scheme.
# Funky though.
sub plasma {
    my $w = 80 - 1; # Dimensions of standard Windows terminal
    my $h = 24 - 1; # 
    
    my @luma = ( ".", "-", "+", "*", "=", "&", "#"  ); # Pixel 'brightness'
    
    &cls();
    print "\n Hold down <Enter> to play plasma animation.\n'ff' skips time.\n'exit' ends.";
    <STDIN>;
    
    my $frame    = 0;          # Frame counter
    my $time     = 0;          # Time index
    my $timestep = 1.0/100.0;  # Timer increment
    my $sinesync = 1.60;       # Sine completes a half cycle every pi*100 frames at frame 160
    my $pi       = 3.14;
    my $exit     = 0;
    
    
    while ( ! $exit) {
        &cls();
        
        my $s = (sin($time+$sinesync) + 1.0) / 2.0; # Range compress sine wave: -1 : 1  ->  0   : 1
           $s = 0.3 + ($s * (1.0-0.3));             # Further range compression: 0 : 1  ->  0.3 : 1
        my $t = $s * 5.0;
        
        for (my $y=1; $y<=$h; $y++) {
        for (my $x=1; $x<=$w; $x++) {
            
            # Dark rituals for the Trig Gods
            my $xo = $x - cos($s*100);
            my $yo = $y + (sin(($x+$frame)/(10))*4.0); # Adds waveform distortion
            my $rx = ((($xo-($w/2))*2) / $w) * $pi * $s * $s * $t;
            my $ry = ((($yo-($h/2))*2) / $h) * $pi * $s * $t;
            my $cx = (cos($rx) + 1.0) / 2.0;
            my $cy = (cos($ry) + 1.0) / 2.0;
            my $sx = (sin($rx) + 1.0) / 2.0;
            my $sy = (sin($ry) + 1.0) / 2.0;

            my @wave;
               $wave[0] = sqrt($cx / $cy) * (1-$s);   # Thinning lines
               $wave[1] = abs(($cy-$sx) * ($sx-$cy)); # Wave deltas
               $wave[2] = abs(sin(($time*16)+$x/4) - cos(($time*-16)+$y/4)) - $sx - ($sy*$sy); # Plasma
               $wave[3] = abs(sin(($time*16)+$x/4) - cos(($time* 16)+$y/4)) + $sx; # Circles
               
               
            # Continuously interpolate between the various wave types in space and time
            my $lerpx = $x / $w; 
            my $lerp  = $lerpx * (abs(&rr($time,1.5))/1.5);
            
            if ($lerp < 0 or $lerp > 1) {
                print "\nBAD LERP: $lerp\n";
            }
            
            my $indexbase = $lerp * (scalar(@wave));
            my $lerpi     = $indexbase - int($indexbase);
            my $ind1      = int($indexbase)  % scalar(@wave);
            my $ind2      = ($ind1 + 1)      % scalar(@wave);
            my $a         = $wave[$ind1];
            my $b         = $wave[$ind2];
            my $alpha     = $a + ( ($b-$a) * (($lerpi**2)*(3.0-(2.0*$lerpi))) ); # Hermite interpolate
            #my $alpha     = $a + (($b-$a)*$lerpi); # Linear
            
            
            # Change falloff
            $alpha *= $alpha;
            
            
            # Put into 0-3 range and clamp.
            my $lsize = scalar(@luma);
            my $lmax  = $lsize - 1;
            
            $alpha *= $lsize;
            $alpha  = ($alpha < 0)     ?     0 : $alpha;
            $alpha  = ($alpha > $lmax) ? $lmax : $alpha;
            
            
            # Perform ordered dithering to approximate gradients between brightnesses
            if ($alpha < 0.1) {
                print " ";
            }
            elsif ($alpha < 0.5 and ($x % 2 == 0 or $y % 2 == 0)) {
                print " ";
            }
            elsif ($alpha>$lmax-0.1) {
                print $luma[ $lmax ];
            }
            elsif ((($alpha*10)%10<5) and ($alpha > 1) and ($x % 2 == 0 or $y % 2 == 0)) {
                print $luma[ $alpha-1 ];
            }
            else {
                print $luma[ $alpha ];
            }
            
            
        }
            print "\n";
        }
        
        $frame++;
        $time += $timestep;
        
        #print "\nF:    $frame";
        #print "\nTime: $time";
        #print "\nS:    $s";
        
        print "> ";
        my $in = <STDIN>;
        chomp($in);
        
        if (&string_match("exit",$in) > 0) { # Exit plasma
            $exit = 1;
        }
        
        if (&string_match("ff",$in) > 0) { # Skip time
            $frame += 180;
            $time  += $timestep*180;
        }
    }
}


# string_overlap( $ref, $comp )
# Returns number of characters that match, counting from
# the start until a mismatch is found.
sub string_overlap {
    my $ref  = shift;
    my $com  = shift;
    my $lenr = length( $ref );
    my $lenc = length( $com );
    my $pos  = 0;
    
    # Make the comparison case-insensitive.
    $ref = lc( $ref );
    $com = lc( $com );
    
    # Find out how far com matches ref.
    while ($pos < $lenc) {        
        if (substr($ref,$pos,1)  eq  substr($com,$pos,1)) {
            $pos++;
        } else {
            return $pos;
        }
    }
    
    return $pos;
}



# string_match( $ref, $comp )
# Returns number of characters that match, but with some additional
# constraints: comp can't be longer and can't have mismatching chars
# or it counts as zero.
# 0 == none / too long / mismatch.
# length(str) == 1:1 match.
sub string_match {
    my $ref  = shift;
    my $com  = shift;
    my $lenr = length( $ref );
    my $lenc = length( $com );
    my $pos  = 0;
    
    # If string under scrutiny is longer than reference
    # string then don't even bother.  It can't match.
    if ($lenc > $lenr) {
        return 0;
    }
    
    # Make the comparison case-insensitive.
    $ref = lc( $ref );
    $com = lc( $com );
    
    # Find out how far com matches ref.
    while ($pos < $lenc) {
        if (substr($ref,$pos,1)  eq  substr($com,$pos,1)) {
            $pos++;
        } else {
            # If string has crap at the end, reject it.
            # Otherwise stuff like "blah123" would match "blah".
            return 0;
        }
    }

    return $pos;
}



# rr( $val, $-+range )
# Range reduction: reduce continous linear input to wrapping +-range
sub rr {
    my $val   = shift;
    my $range = shift;
    
    $val = &fmods( $val+$range, $range*2.0 ) - $range;
    $val = ($val < -$range)  ?  ($val+$range*2.0) : ($val);

    return $val;
}



# fmods(x,mod)
# Floating point modulo
sub fmods {
    my $x    = shift;
    my $mod  = shift;
    
    my $rcpm = (1.0/$mod) * $x;
    my $frac = $rcpm - int($rcpm);
    
    return $mod * $frac;
}



# cls()
# Clear console window using the OS-appropriate shell command.
# Cribbed from Paul.
sub cls {
    system( ($^O eq 'MSWin32')  ?  "cls"  :  "clear" );
}









































