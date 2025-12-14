############################################################################
#
#  W2 Animator
#  Miscellaneous Utilities
#  Copyright (c) 2022-2025, Stewart A. Rounds
#
#  Contact:
#    Stewart A. Rounds
#    roundsstewart@gmail.com
#
#  This program is free software; you may redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 3
#  of the License or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
############################################################################

#
# Utilities list:
#
# Date subroutines:
#   set_leap_year
#   found_date
#   parse_date
#   get_datetime
#   get_formatted_date
#   merge_dates
#   truncate_dates
#   date2datelabel
#   format_datelabel
#   date2jdate
#   dates2jdates
#   datelabel2date
#   datelabel2jdate
#   jdate2date
#   jdate2datelabel
#   jdates2datelabels
#   nearest_daily_dt
#   get_dt_diff
#   nearest_dt_index
#   adjust_dt
#   adjust_dt_by_day
#
# String subroutines:
#   list_match
#   list_search
#   string_search
#
# Math subroutines:
#   numerically
#   floor
#   ceil
#   min
#   max
#   sum
#   round_to_int
#   sign
#   get_random_number
#   log10
#
# Array subroutines:
#   get_sort_index
#   rearrange_array
#
# Basic interface subroutines:
#   native_optionmenu
#   open_url
#   pop_up_info
#   pop_up_error
#   pop_up_question
#
# Subroutines for standard graph parts:
#   make_axis
#   make_seg_axis
#   make_date_axis
#   find_axis_limits
#   make_color_key
#   make_ts_legend
#   image_put_color
#   paint_slice_cell
#   make_curve
#
# Clipping subroutines:
#   clip_profile
#
# Point manipulations:
#   purge_points
#   rdp_resample
#   perp_dist
#
# Trig calculation subroutines:
#   make_shape_coords
#   find_rect_from_shape
#   find_rect_from_poly
#   resize_shape
#
# Multidimensional minimization subroutines:
#   smallest_circle
#   max_dist
#   fit_curve
#   curve_error
#   curve_error2
#   get_fval
#   amoeba
#

#
# Load important modules
# Use the Perl Math::Bezier module for curves. No curves option if module not found.
#
use strict;
use warnings;
use diagnostics;
use Math::Trig qw(pi acos_real);
my $Bezier_OK = 1;
unless (eval "use Math::Bezier; 1") {
    $Bezier_OK = 0;
}

# Global variables
our (
     @days_in_month, @mon_names, @month_names, @tz_offsets,
    );

# Claim some local variables.
my (
    $DD_Mon_YYYY_fmt, $DD_Mon_YYYY_HHmm_fmt, $hr, $MM_DD_YYYY_fmt,
    $MM_DD_YYYY_HHmm_fmt, $Mon_DD_YYYY_fmt, $Mon_DD_YYYY_HHmm_fmt,
    $YYYY_MM_DD_fmt, $YYYY_MM_DD_HHmm_fmt, $YYYYMMDD_fmt, $YYYYMMDD_HHmm_fmt,
    $YYYYMMDDHHmm_fmt,
   );

# Set some date-related arrays and variables.
@mon_names       = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@month_names     = qw(January February March April May June July
                      August September October November December);
@days_in_month   = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

$DD_Mon_YYYY_fmt = "[0-3]?[0-9][-/][a-z][a-z][a-z][-/][12][0-9][0-9][0-9]";
$Mon_DD_YYYY_fmt = "[a-z][a-z][a-z][-/][0-3]?[0-9][-/][12][0-9][0-9][0-9]";
$MM_DD_YYYY_fmt  = "[01]?[0-9][-/][0-3]?[0-9][-/][12][0-9][0-9][0-9]";
$YYYY_MM_DD_fmt  = "[12][0-9][0-9][0-9][-/][01]?[0-9][-/][0-3]?[0-9]";
$YYYYMMDD_fmt    = "[12][0-9][0-9][0-9][01][0-9][0-3][0-9]";

$DD_Mon_YYYY_HHmm_fmt = "[0-3]?[0-9][-/][a-z][a-z][a-z][-/][12][0-9][0-9][0-9][ \tT][0-2]?[0-9]:?[0-5][0-9]";
$Mon_DD_YYYY_HHmm_fmt = "[a-z][a-z][a-z][-/][0-3]?[0-9][-/][12][0-9][0-9][0-9][ \tT][0-2]?[0-9]:?[0-5][0-9]";
$MM_DD_YYYY_HHmm_fmt  = "[01]?[0-9][-/][0-3]?[0-9][-/][12][0-9][0-9][0-9][ \tT][0-2]?[0-9]:?[0-5][0-9]";
$YYYY_MM_DD_HHmm_fmt  = "[12][0-9][0-9][0-9][-/][01]?[0-9][-/][0-3]?[0-9][ \tT][0-2]?[0-9]:?[0-5][0-9]";
$YYYYMMDD_HHmm_fmt    = "[12][0-9][0-9][0-9][01][0-9][0-3][0-9][ \tT][0-2][0-9][0-5][0-9]";
$YYYYMMDDHHmm_fmt     = "[12][0-9][0-9][0-9][01][0-9][0-3][0-9][0-2][0-9][0-5][0-9]";

@tz_offsets = ();
for ($hr=-24; $hr<=24; $hr++) {
    if ($hr >= 0) {
        push (@tz_offsets, sprintf("+%02d:%02d", $hr,  0));
        push (@tz_offsets, sprintf("+%02d:%02d", $hr, 30)) if ($hr < 24);
    } else {
        push (@tz_offsets, sprintf("%+03d:%02d", $hr, 30)) if ($hr > -24);
        push (@tz_offsets, sprintf("%+03d:%02d", $hr,  0));
        push (@tz_offsets, "-00:30") if ($hr == -1);
    }
}


################################################################################
#
# Date subroutines
#
################################################################################

sub set_leap_year {
    $days_in_month[1] = ( $_[0] % 4 == 0 ) ? 29 : 28;
}


sub found_date {
    my ($line) = @_;
    my ($date_found, $date_only);

    $date_found = $date_only = 0;
    $line =~ s/^\s+//;
    if ($line =~ /^$DD_Mon_YYYY_HHmm_fmt/i || $line =~ /^$Mon_DD_YYYY_HHmm_fmt/i ||
        $line =~ /^$MM_DD_YYYY_HHmm_fmt/   || $line =~ /^$YYYY_MM_DD_HHmm_fmt/   ||
        $line =~ /^$YYYYMMDD_HHmm_fmt/     || $line =~ /^$YYYYMMDDHHmm_fmt/ ) {
        $date_found = 1;

    } elsif ($line =~ /^$DD_Mon_YYYY_fmt/i || $line =~ /^$Mon_DD_YYYY_fmt/i ||
             $line =~ /^$MM_DD_YYYY_fmt/   || $line =~ /^$YYYY_MM_DD_fmt/   ||
             $line =~ /^$YYYYMMDD_fmt/ ) {
        $date_found = 1;
        $date_only  = 1;
    }
    return ($date_found, $date_only);
}


sub parse_date {
    my ($dt, $date_only) = @_;
    my ($y, $m, $mon, $d, $h, $mi);

    $dt =~ s/^\s+//;
    if ($date_only) {
        if ($dt =~ /$YYYYMMDD_fmt/) {
            $y = substr($dt,0,4);
            $m = substr($dt,4,2);
            $d = substr($dt,6,2);
        } elsif ($dt =~ /$DD_Mon_YYYY_fmt/i) {
            ($d, $mon, $y) = split(/-|\//, $dt);
            $mon = ucfirst(lc($mon));
            $m   = &list_match($mon, @mon_names) +1;
        } elsif ($dt =~ /$Mon_DD_YYYY_fmt/i) {
            ($mon, $d, $y) = split(/-|\//, $dt);
            $mon = ucfirst(lc($mon));
            $m   = &list_match($mon, @mon_names) +1;
        } elsif ($dt =~ /$MM_DD_YYYY_fmt/) {
            ($m, $d, $y) = split(/-|\//, $dt);
        } elsif ($dt =~ /$YYYY_MM_DD_fmt/) {
            ($y, $m, $d) = split(/-|\//, $dt);
        } else {
            return -1;
        }
        return ($m, $d, $y);
    } else {
        if ($dt =~ /$YYYYMMDDHHmm_fmt/) {
            $y  = substr($dt, 0,4);
            $m  = substr($dt, 4,2);
            $d  = substr($dt, 6,2);
            $h  = substr($dt, 8,2);
            $mi = substr($dt,10,2);
        } elsif ($dt =~ /$YYYYMMDD_HHmm_fmt/) {
            $y  = substr($dt, 0,4);
            $m  = substr($dt, 4,2);
            $d  = substr($dt, 6,2);
            $h  = substr($dt, 9,2);
            $mi = substr($dt,11,2);
        } elsif ($dt =~ /$DD_Mon_YYYY_HHmm_fmt/i) {
            ($d, $mon, $y, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
            $mon = ucfirst(lc($mon));
            $m   = &list_match($mon, @mon_names) +1;
        } elsif ($dt =~ /$Mon_DD_YYYY_HHmm_fmt/i) {
            ($mon, $d, $y, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
            $mon = ucfirst(lc($mon));
            $m   = &list_match($mon, @mon_names) +1;
        } elsif ($dt =~ /$MM_DD_YYYY_HHmm_fmt/) {
            ($m, $d, $y, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
        } elsif ($dt =~ /$YYYY_MM_DD_HHmm_fmt/) {
            ($y, $m, $d, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
        } else {
            return -1;
        }
        return ($m, $d, $y, $h, $mi);
    }
}


sub get_datetime {
    my ($mi, $h, $d, $m, $y, $wday, $mon, $day, $datetime);

    (undef,$mi,$h,$d,$m,$y,$wday,undef,undef) = localtime(time);
    $mon = $mon_names[$m];
    $day = ("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")[$wday];
    $y  += 1900;
    $datetime = sprintf("%s, %2d-%s-%04d %2d:%02d", $day, $d, $mon, $y, $h, $mi);
    return $datetime;
}


sub get_formatted_date {
    my ($dt, $short, $fmt) = @_;
    my ($y, $m, $d, $h, $mi, $str);

    $y = substr($dt,0,4);
    $m = substr($dt,4,2);
    $d = substr($dt,6,2);
    $short = 0 if (! defined($short) || $short ne "1");
    $fmt   = "DD-Mon-YYYY HH:mm" if (! defined($fmt) || $fmt eq "");

    if (length($dt) == 8) {
        if ($short) {
            if ($fmt =~ /DD-Mon-YYYY/) {
                $str = sprintf("%2d-%s-%04d", $d, $mon_names[$m-1], $y);
            } elsif ($fmt =~ /DD Mon, YYYY/) {
                $str = sprintf("%2d %s, %04d", $d, $mon_names[$m-1], $y);
            } elsif ($fmt =~ /Mon DD, YYYY/) {
                $str = sprintf("%s %2d, %04d", $mon_names[$m-1], $d, $y);
            } elsif ($fmt =~ /MM\/DD\/YYYY/) {
                $str = sprintf("%2d/%s/%04d", $m, $d, $y);
            } elsif ($fmt =~ /MM-DD-YYYY/) {
                $str = sprintf("%2d-%s-%04d", $m, $d, $y);
            } else {
                $str = sprintf("%2d-%s-%04d", $d, $mon_names[$m-1], $y);
            }
        } else {
            $str = sprintf("%2d %s, %04d", $d, $month_names[$m-1], $y);
        }
    } else {
        $h  = substr($dt, 8,2);
        $mi = substr($dt,10,2);
        if ($short) {
            if ($fmt eq "DD-Mon-YYYY HH:mm") {
                $str = sprintf("%2d-%s-%04d %2d:%02d", $d, $mon_names[$m-1], $y, $h, $mi);
            } elsif ($fmt eq "DD Mon, YYYY HH:mm") {
                $str = sprintf("%2d %s, %04d %2d:%02d", $d, $mon_names[$m-1], $y, $h, $mi);
            } elsif ($fmt eq "Mon DD, YYYY HH:mm") {
                $str = sprintf("%s %2d, %04d %2d:%02d", $mon_names[$m-1], $d, $y, $h, $mi);
            } elsif ($fmt eq "MM/DD/YYYY HH:mm") {
                $str = sprintf("%2d/%02d/%04d %2d:%02d", $m, $d, $y, $h, $mi);
            } elsif ($fmt eq "MM-DD-YYYY HH:mm") {
                $str = sprintf("%2d-%02d-%04d %2d:%02d", $m, $d, $y, $h, $mi);
            } else {
                $str = sprintf("%2d-%s-%04d %2d:%02d", $d, $mon_names[$m-1], $y, $h, $mi);
            }
        } else {
            $str = sprintf("%2d %s, %04d %2d:%02d", $d, $month_names[$m-1], $y, $h, $mi);
        }
    }
    return $str;
}


sub merge_dates {
    my ($a_ref, $b_ref) = @_;
    my ($a_daily, $b_daily, $crit, $i, $last_a, $x,
        @a, @b, @uniq,
        %seen,
       );

    @a = @{ $a_ref };
    @b = @{ $b_ref };
    $a_daily = (length($a[0]) == 12) ? 0 : 1;
    $b_daily = (length($b[0]) == 12) ? 0 : 1;
    if ($a_daily && ! $b_daily) {
        foreach $x (@a) { $x *= 10000; }  # Add HHMM digits to @a dates
    } elsif ($b_daily && ! $a_daily) {
        foreach $x (@b) { $x *= 10000; }  # Add HHMM digits to @b dates
    }
    push (@a, @b);
    %seen = ();
    @uniq = grep { ! $seen{ $_ }++ } @a;  # use hash and grep to find unique array members

    if ($a_daily && $b_daily) {
        return sort @uniq;
    } else {
        @uniq = sort @uniq;
        $crit = 5./1440.;                 # 5 minutes
        @a    = ();
        $a[0] = $last_a = $uniq[0];
        for ($i=1; $i<=$#uniq; $i++) {    # eliminate dates within 5 minutes of each other
            if (&date2jdate($uniq[$i]) -&date2jdate($last_a) > $crit) {
                push (@a, $uniq[$i]);
                $last_a = $uniq[$i];
            }
        }
        return @a;
    }
}


sub truncate_dates {
    my ($dt_begin, $dt_end, @dates) = @_;
    my ($pos);

#   Format is YYYYMMDDHHmm for dt_begin and dt_end. Dates array could be YYYYMMDD.
    if (length($dates[0]) == 8) {               # daily
        $dt_begin = substr($dt_begin,0,8);
        $dt_end   = substr($dt_end,  0,8);
    }

#   Truncate the dates array
    if ($dt_begin > $dates[0] && $dt_end < $dates[$#dates]) {
        push (@dates, $dt_begin, $dt_end);
        @dates = sort @dates;
        $pos   = 1+ &list_match($dt_begin, @dates);
        splice(@dates, 0, $pos);
        $pos   = -1* (1+ &list_match($dt_end, reverse @dates));
        splice(@dates, $pos);
    } elsif ($dt_begin > $dates[0]) {
        push (@dates, $dt_begin);
        @dates = sort @dates;
        $pos   = 1+ &list_match($dt_begin, @dates);
        splice(@dates, 0, $pos);
    } elsif ($dt_end < $dates[$#dates]) {
        push (@dates, $dt_end);
        @dates = sort @dates;
        $pos   = -1* (1+ &list_match($dt_end, reverse @dates));
        splice(@dates, $pos);
    }
    return @dates;
}


sub date2datelabel {
    my ($dt, $fmt) = @_;
    my ($y, $d, $m, $h, $mi, $label);

    $y = substr($dt,0,4);
    $m = substr($dt,4,2);
    $d = substr($dt,6,2);
    if (length($dt) == 12) {
        $h  = substr($dt, 8,2);
        $mi = substr($dt,10,2);
    } else {
        $h = $mi = 0;
    }

    if ($fmt eq "Mon-DD-YYYY") {
        $label = sprintf("%s-%02d-%04d", $mon_names[$m-1], $d, $y);
    } elsif ($fmt eq "Mon-DD") {
        $label = sprintf("%s-%02d", $mon_names[$m-1], $d);
    } elsif ($fmt eq "Month") {
        $label = $month_names[$m-1];
    } elsif ($fmt eq "Mon") {
        $label = $mon_names[$m-1];
    } elsif ($fmt eq "M") {
        $label = substr($mon_names[$m-1],0,1);
    } elsif ($fmt eq "Mon-DD-YYYY HH:mm") {
        $label = sprintf("%s-%02d-%04d %2d:%02d", $mon_names[$m-1], $d, $y, $h, $mi);
    } else {
        $label = sprintf("%04d-%02d-%02d", $y, $m, $d);
    }
    return $label;
}


sub format_datelabel {
    my ($dt, $fmt) = @_;
    my ($d, $h, $label, $m, $mon, $mi, $y);

    $h = $mi = 0;

    if ($dt =~ /$YYYYMMDDHHmm_fmt/) {
        $y  = substr($dt, 0,4);
        $m  = substr($dt, 4,2);
        $d  = substr($dt, 6,2);
        $h  = substr($dt, 8,2);
        $mi = substr($dt,10,2);
    } elsif ($dt =~ /$YYYYMMDD_HHmm_fmt/) {
        $y  = substr($dt, 0,4);
        $m  = substr($dt, 4,2);
        $d  = substr($dt, 6,2);
        $h  = substr($dt, 9,2);
        $mi = substr($dt,11,2);
    } elsif ($dt =~ /$DD_Mon_YYYY_HHmm_fmt/i) {
        ($d, $mon, $y, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
        $mon = ucfirst(lc($mon));
        $m   = &list_match($mon, @mon_names) +1;
    } elsif ($dt =~ /$Mon_DD_YYYY_HHmm_fmt/i) {
        ($mon, $d, $y, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
        $mon = ucfirst(lc($mon));
        $m   = &list_match($mon, @mon_names) +1;
    } elsif ($dt =~ /$MM_DD_YYYY_HHmm_fmt/) {
        ($m, $d, $y, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
    } elsif ($dt =~ /$YYYY_MM_DD_HHmm_fmt/) {
        ($y, $m, $d, $h, $mi) = split(/-|\/| |\t|T|:/, $dt);
    } elsif ($dt =~ /$YYYYMMDD_fmt/) {
        $y = substr($dt,0,4);
        $m = substr($dt,4,2);
        $d = substr($dt,6,2);
    } elsif ($dt =~ /$DD_Mon_YYYY_fmt/i) {
        ($d, $mon, $y) = split(/-|\//, $dt);
        $mon = ucfirst(lc($mon));
        $m   = &list_match($mon, @mon_names) +1;
    } elsif ($dt =~ /$Mon_DD_YYYY_fmt/i) {
        ($mon, $d, $y) = split(/-|\//, $dt);
        $mon = ucfirst(lc($mon));
        $m   = &list_match($mon, @mon_names) +1;
    } elsif ($dt =~ /$MM_DD_YYYY_fmt/) {
        ($m, $d, $y) = split(/-|\//, $dt);
    } elsif ($dt =~ /$YYYY_MM_DD_fmt/) {
        ($y, $m, $d) = split(/-|\//, $dt);
    } else {
        return -1;
    }

    if ($fmt eq "YYYYMMDDHHmm") {
        $label = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
    } elsif ($fmt eq "YYYYMMDD HHmm") {
        $label = sprintf("%04d%02d%02d %02d%02d", $y, $m, $d, $h, $mi);
    } elsif ($fmt eq "YYYYMMDD HH:mm") {
        $label = sprintf("%04d%02d%02d %2d:%02d", $y, $m, $d, $h, $mi);
    } elsif ($fmt eq "DD-Mon-YYYY HH:mm") {
        $label = sprintf("%2d-%s-%04d %2d:%02d", $d, $mon_names[$m-1], $y, $h, $mi);
    } elsif ($fmt eq "DD/Mon/YYYY HH:mm") {
        $label = sprintf("%2d/%s/%04d %2d:%02d", $d, $mon_names[$m-1], $y, $h, $mi);
    } elsif ($fmt eq "Mon-DD-YYYY HH:mm") {
        $label = sprintf("%s-%02d-%04d %2d:%02d", $mon_names[$m-1], $d, $y, $h, $mi);
    } elsif ($fmt eq "Mon/DD/YYYY HH:mm") {
        $label = sprintf("%s/%02d/%04d %2d:%02d", $mon_names[$m-1], $d, $y, $h, $mi);
    } elsif ($fmt eq "MM-DD-YYYY HH:mm") {
        $label = sprintf("%2d-%02d-%04d %2d:%02d", $m, $d, $y, $h, $mi);
    } elsif ($fmt eq "MM/DD/YYYY HH:mm") {
        $label = sprintf("%2d/%02d/%04d %2d:%02d", $m, $d, $y, $h, $mi);
    } elsif ($fmt eq "YYYY-MM-DD HH:mm") {
        $label = sprintf("%04d-%02d-%02d %2d:%02d", $y, $m, $d, $h, $mi);
    } elsif ($fmt eq "YYYY/MM/DD HH:mm") {
        $label = sprintf("%04d/%02d/%02d %2d:%02d", $y, $m, $d, $h, $mi);
    } elsif ($fmt eq "YYYYMMDD") {
        $label = sprintf("%04d%02d%02d", $y, $m, $d);
    } elsif ($fmt eq "DD-Mon-YYYY") {
        $label = sprintf("%2d-%s-%04d", $d, $mon_names[$m-1], $y);
    } elsif ($fmt eq "DD/Mon/YYYY HH:mm") {
        $label = sprintf("%2d/%s/%04d", $d, $mon_names[$m-1], $y);
    } elsif ($fmt eq "Mon-DD-YYYY") {
        $label = sprintf("%s-%02d-%04d", $mon_names[$m-1], $d, $y);
    } elsif ($fmt eq "Mon/DD/YYYY") {
        $label = sprintf("%s/%02d/%04d", $mon_names[$m-1], $d, $y);
    } elsif ($fmt eq "MM-DD-YYYY") {
        $label = sprintf("%2d-%02d-%04d", $m, $d, $y);
    } elsif ($fmt eq "MM/DD/YYYY") {
        $label = sprintf("%2d/%02d/%04d", $m, $d, $y);
    } elsif ($fmt eq "YYYY-MM-DD") {
        $label = sprintf("%04d-%02d-%02d", $y, $m, $d);
    } elsif ($fmt eq "YYYY/MM/DD") {
        $label = sprintf("%04d/%02d/%02d", $y, $m, $d);
    } elsif ($fmt eq "Mon-DD") {
        $label = sprintf("%s-%02d", $mon_names[$m-1], $d);
    } elsif ($fmt eq "Month") {
        $label = $month_names[$m-1];
    } elsif ($fmt eq "Mon") {
        $label = $mon_names[$m-1];
    } elsif ($fmt eq "M") {
        $label = substr($mon_names[$m-1],0,1);
    } else {
        $label = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
    }
    return $label;
}


sub date2jdate {
    my ($dt) = @_;
    my ($y, $m, $d, $jd, $j, $h, $mi);

#   Use January 1, 1960 as a reference date

    $y = substr($dt,0,4);
    $m = substr($dt,4,2);
    $d = substr($dt,6,2);
    &set_leap_year($y);
    $jd = 29 -$days_in_month[1] + &floor(($y-1960)*365.25 +0.0000001) +$d -1;
    for ($j=0; $j<$m-1; $j++) {
        $jd += $days_in_month[$j];
    }
    if (length($dt) == 12) {
        $h  = substr($dt, 8,2);
        $mi = substr($dt,10,2);
        $jd = sprintf("%.4f", $jd +$h/24. +$mi/1440.);
    }
    return $jd;
}


sub dates2jdates {
    my (@dt) = @_;
    my ($i, $y, $m, $d, $jd, $j, $h, $mi,
        @jdates,
       );

#   Use January 1, 1960 as a reference date

    @jdates = ();
    for ($i=0; $i<=$#dt; $i++) {
        $y = substr($dt[$i],0,4);
        $m = substr($dt[$i],4,2);
        $d = substr($dt[$i],6,2);
        &set_leap_year($y);
        $jd = 29 -$days_in_month[1] + &floor(($y-1960)*365.25 +0.0000001) +$d -1;
        for ($j=0; $j<$m-1; $j++) {
            $jd += $days_in_month[$j];
        }
        if (length($dt[$i]) == 12) {
            $h  = substr($dt[$i], 8,2);
            $mi = substr($dt[$i],10,2);
            $jd = sprintf("%.4f", $jd +$h/24. +$mi/1440.);
        }
        push (@jdates, $jd);
    }
    return @jdates;
}


sub datelabel2date {
    my ($dl) = @_;
    my ($d, $m, $mon, $y);

    if ($dl =~ /$Mon_DD_YYYY_fmt/i) {
        ($mon, $d, $y) = split(/-|\//, $dl);
        $mon = ucfirst(lc($mon));
        $m   = &list_match($mon, @mon_names) +1;
    }
    return sprintf("%04d%02d%02d", $y, $m, $d);
}


sub datelabel2jdate {
    my ($dl) = @_;
    my ($d, $h, $jd, $j, $m, $mi, $mon, $y);

#   Use January 1, 1960 as a reference date

    if ($dl =~ /$Mon_DD_YYYY_fmt/i) {
        ($mon, $d, $y) = split(/-|\//, $dl);
        $mon = ucfirst(lc($mon));
        $m   = &list_match($mon, @mon_names) +1;
    }
    &set_leap_year($y);
    $jd = 29 -$days_in_month[1] + &floor(($y-1960)*365.25 +0.0000001) +$d -1;
    for ($j=0; $j<$m-1; $j++) {
        $jd += $days_in_month[$j];
    }
    return $jd;
}


sub jdate2date {
    my ($jd) = @_;
    my ($d, $dt, $h, $m, $mi, $y);

#   Reference date is January 1, 1960

    if ($jd >= 0) {
        $y = 1960 + int(($jd-60)/365.25 +0.0000001);
        &set_leap_year($y);
        $d = $days_in_month[1] -29 +int($jd) -int(($y-1960)*365.25 +0.0000001) +1;
    } else {
        $y = 1960 + &floor($jd/365.25 -0.0000001);
        &set_leap_year($y);
        $d = &floor($jd) +int((1960-$y)*365.25 +0.0000001) +1;
    }
    $m = 0;
    until ($d <= $days_in_month[$m]) {
        $d -= $days_in_month[$m];
        $m++;
        if ($m > 11) {
            $m = 0;
            $y++;
            &set_leap_year($y);
        }
    }
    $h = $mi = 0;
    if (abs($jd - &floor($jd +0.0000001)) >= 0.5/1440.) {
        $mi  = &round_to_int(abs($jd - &floor($jd +0.0000001)) *1440.);
        $h   = int($mi /60 +0.0000001);
        $mi -= $h *60;
        if ($h == 24) {
            $h = 0;
            $d++;
            if ($d > $days_in_month[$m]) {
                $d -= $days_in_month[$m];
                $m++;
                if ($m > 11) {
                    $m = 0;
                    $y++;
                }
            }
        }
    }
    $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m+1, $d, $h, $mi);

    return $dt;
}


sub jdate2datelabel {
    my ($jd, $fmt) = @_;
    my ($y, $d, $m, $h, $mi, $label);

#   Reference date is January 1, 1960

    $jd = &floor($jd +0.0000001);
    if ($jd >= 0) {
        $y = 1960 + int(($jd-60)/365.25 +0.0000001);
        &set_leap_year($y);
        $d = $days_in_month[1] -29 +int($jd) -int(($y-1960)*365.25 +0.0000001) +1;
    } else {
        $y = 1960 + &floor($jd/365.25 -0.0000001);
        &set_leap_year($y);
        $d = &floor($jd) +int((1960-$y)*365.25 +0.0000001) +1;
    }
    $m = 0;
    until ($d <= $days_in_month[$m]) {
        $d -= $days_in_month[$m];
        $m++;
        if ($m > 11) {
            $m = 0;
            $y++;
            &set_leap_year($y);
        }
    }
    $h = $mi = 0;
    if (abs($jd - &floor($jd +0.0000001)) >= 0.5/1440.) {
        $mi  = &round_to_int(abs($jd - &floor($jd +0.0000001)) *1440.);
        $h   = int($mi /60 +0.0000001);
        $mi -= $h *60;
        if ($h == 24) {
            $h = 0;
            $d++;
            if ($d > $days_in_month[$m]) {
                $d -= $days_in_month[$m];
                $m++;
                if ($m > 11) {
                    $m = 0;
                    $y++;
                }
            }
        }
    }
    if ($fmt eq "Mon-DD-YYYY") {
        $label = sprintf("%s-%02d-%04d", $mon_names[$m], $d, $y);
    } elsif ($fmt eq "Mon-DD") {
        $label = sprintf("%s-%02d", $mon_names[$m], $d);
    } elsif ($fmt eq "Month") {
        $label = $month_names[$m];
    } elsif ($fmt eq "Mon") {
        $label = $mon_names[$m];
    } elsif ($fmt eq "M") {
        $label = substr($mon_names[$m],0,1);
    } elsif ($fmt eq "Year") {
        $label = sprintf("%4d", $y);
    } else {
        $label = sprintf("%04d-%02d-%02d", $y, $m+1, $d);
    }
    return $label;
}


sub jdates2datelabels {
    my ($fmt, @jds) = @_;
    my ($i, $jd, $y, $d, $m, $h, $mi, $label,
        @labels,
       );

#   Reference date is January 1, 1960

    for ($i=0; $i<=$#jds; $i++) {
        $jd = &floor($jds[$i] +0.0000001);
        if ($jd >= 0) {
            $y = 1960 + int(($jd-60)/365.25 +0.0000001);
            &set_leap_year($y);
            $d = $days_in_month[1] -29 +int($jd) -int(($y-1960)*365.25 +0.0000001) +1;
        } else {
            $y = 1960 + &floor($jd/365.25 -0.0000001);
            &set_leap_year($y);
            $d = &floor($jd) +int((1960-$y)*365.25 +0.0000001) +1;
        }
        $m = 0;
        until ($d <= $days_in_month[$m]) {
            $d -= $days_in_month[$m];
            $m++;
            if ($m > 11) {
                $m = 0;
                $y++;
                &set_leap_year($y);
            }
        }
        $h = $mi = 0;
        if (abs($jd - &floor($jd +0.0000001)) >= 0.5/1440.) {
            $mi  = &round_to_int(abs($jd - &floor($jd +0.0000001)) *1440.);
            $h   = int($mi /60 +0.0000001);
            $mi -= $h *60;
            if ($h == 24) {
                $h = 0;
                $d++;
                if ($d > $days_in_month[$m]) {
                    $d -= $days_in_month[$m];
                    $m++;
                    if ($m > 11) {
                        $m = 0;
                        $y++;
                    }
                }
            }
        }
        if ($fmt eq "Mon-DD-YYYY") {
            $label = sprintf("%s-%02d-%04d", $mon_names[$m], $d, $y);
        } elsif ($fmt eq "Mon-DD") {
            $label = sprintf("%s-%02d", $mon_names[$m], $d);
        } elsif ($fmt eq "Month") {
            $label = $month_names[$m];
        } elsif ($fmt eq "Mon") {
            $label = $mon_names[$m];
        } elsif ($fmt eq "M") {
            $label = substr($mon_names[$m],0,1);
        } else {
            $label = sprintf("%04d-%02d-%02d", $y, $m+1, $d);
        }
        push (@labels, $label);
    }
    return @labels;
}


sub nearest_daily_dt {
    my ($dt) = @_;
    my ($d, $h, $m, $y);

    $y = substr($dt,0,4);
    $m = substr($dt,4,2);
    $d = substr($dt,6,2);
    $h = substr($dt,8,2);
    if ($h >= 12) {
        $d++;
        &set_leap_year($y);
        $m++ if ($d > $days_in_month[$m-1]);
        if ($m > 12) {
            $m = 1;
            $y++;
        }
        $dt = sprintf("%04d%02d%02d", $y, $m, $d);
    } else {
        $dt = substr($dt,0,8);
    }
    return $dt;
}


sub get_dt_diff {            # difference in minutes between two dates
    my ($dt1, $dt2) = @_;
    my ($diff);

    $diff = abs(&date2jdate($dt1) - &date2jdate($dt2)) *1440.;
    return $diff;
}


sub nearest_dt_index {
    my ($dt, @dates) = @_;
    my ($indx, $mi, $dt2);

    $indx = &list_match($dt, @dates);
    return $indx if ($indx >= 0);
    return -1 if (length($dt) == 8 && length($dates[0]) == 8);
    for ($mi=1; $mi<=10; $mi++) {
        $dt2  = &adjust_dt($dt, $mi);
        $indx = &list_match($dt2, @dates);
        last if ($indx >= 0);
        $dt2  = &adjust_dt($dt, -1 *$mi);
        $indx = &list_match($dt2, @dates);
        last if ($indx >= 0);
    }
    return $indx;
}


sub adjust_dt {
    my ($dt, $add) = @_;
    my ($d, $h, $m, $mi, $y);

    return $dt if (length($dt) == 8);

    $y  = substr($dt, 0,4);
    $m  = substr($dt, 4,2);
    $d  = substr($dt, 6,2);
    $h  = substr($dt, 8,2);
    $mi = substr($dt,10,2);
    &set_leap_year($y);

    $mi += $add;
    until ($mi >= 0 && $mi < 60) {
        if ($mi < 0) {
            $mi += 60;
            $h--;
            if ($h < 0) {
                $h += 24;
                $d--;
                if ($d < 1) {
                    $m--;
                    if ($m < 1) {
                        $m = 12;
                        $y--;
                        &set_leap_year($y);
                    }
                    $d += $days_in_month[$m-1];
                }
            }
        } elsif ($mi >= 60) {
            $mi -= 60;
            $h++;
            if ($h > 23) {
                $h -= 24;
                $d++;
                if ($d > $days_in_month[$m-1]) {
                    $d -= $days_in_month[$m-1];
                    $m++;
                    if ($m > 12) {
                        $m = 1;
                        $y++;
                        &set_leap_year($y);
                    }
                }
            }
        }
    }
    $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
    return $dt;
}


sub adjust_dt_by_day {
    my ($dt, $add) = @_;
    my ($d, $m, $y);

    $y = substr($dt, 0,4);
    $m = substr($dt, 4,2);
    $d = substr($dt, 6,2);

    &set_leap_year($y);

    $d += $add;
    until ($d >= 1 && $d <= $days_in_month[$m-1]) {
        if ($d < 1) {
            $m--;
            if ($m < 1) {
                $m = 12;
                $y--;
                &set_leap_year($y);
            }
            $d += $days_in_month[$m-1];
        } elsif ($d > $days_in_month[$m-1]) {
            $d -= $days_in_month[$m-1];
            $m++;
            if ($m > 12) {
                $m = 1;
                $y++;
                &set_leap_year($y);
            }
        }
    }
    return sprintf("%04d%02d%02d", $y, $m, $d);
}


################################################################################
#
# String subroutines
#
################################################################################

sub list_match {
    # Search a list for an exact match using a supplied string.
    # Return its ordinal, or -1 if not found.
    my ($s, @list) = @_;
    my ($i);

    for ($i=0; $i<=$#list; $i++) {
        return $i if ($list[$i] eq $s);
    }
    return -1;
}


sub list_search {
    # Search a list using a supplied regular expression.
    # Return its ordinal, or -1 if not found.
    my ($regexp, @list) = @_;
    my ($i);

    for ($i=0; $i<=$#list; $i++) {
        return $i if ($list[$i] =~ /$regexp/);
    }
    return -1;
}


sub string_search {
    # Search a string for the occurrence of any member of a list.
    # Return ordinal of list member that matched, or -1 if not found.
    my ($str, @list) = @_;
    my ($i);

    for ($i=0; $i<=$#list; $i++) {
        return $i if ($str =~ /$list[$i]/);
    }
    return -1;
}


################################################################################
#
# Math subroutines
#
################################################################################

sub numerically { $a <=> $b; }


sub floor {
    my ($v) = @_;
    return int($v) if ($v > 0 || $v == int($v));
    return int($v) -1;
}


sub ceil {
    my ($v) = @_;
    return int($v) if ($v < 0 || $v == int($v));
    return int($v+1);
}


sub min {
    # Find the minimum of a list of numbers.
    my (@a) = @_;
    my ($i, $min);

    $min = $a[0];
    for ($i=1; $i<=$#a; $i++) {
        $min = $a[$i] if ($a[$i] < $min);
    }
    return $min;
}


sub max {
    # Find the maximum of a list of numbers.
    my (@a) = @_;
    my ($i, $max);

    $max = $a[0];
    for ($i=1; $i<=$#a; $i++) {
        $max = $a[$i] if ($a[$i] > $max);
    }
    return $max;
}


sub sum {
    # Find the sum of a list of numbers.
    my (@a) = @_;
    my ($i, $sum);

    $sum = $a[0];
    for ($i=1; $i<=$#a; $i++) {
        $sum += $a[$i];
    }
    return $sum;
}


sub round_to_int {
    # Round to nearest integer.  Accounts for negative values.
    return int(abs($_[0]) +0.5) * ($_[0] < 0 ? -1 : 1);
}


sub sign {            # Return the value of A with the sign of B.
    my ($a, $b) = @_;
    if ($b < 0.0) {
        return abs($a) * -1.0;
    } else {
        return abs($a);
    }
}


sub get_random_number {
    my (@dt, $hhmm, $rn);

    srand(time ^ ($$ + ($$ << 15)));
    @dt   = localtime(time);
    $hhmm = sprintf("%02d%02d", $dt[2], $dt[1]);
    $rn   = int(rand(1000)) . $hhmm;
    return $rn;
}


sub log10 {
    return log($_[0]) /log(10);
}


################################################################################
#
# Array subroutines
#
################################################################################

sub get_sort_index {
    my ($direction, @a) = @_;
    my ($i, $sorted, @b, @indx);

#   Sort the array
    if ($direction eq "ascending") {
        @b = sort numerically @a;
    } else {
        @b = reverse sort numerically @a;
    }

#   Test whether array is already sorted
    @indx   = ();
    $sorted = 1;
    for ($i=0; $i<=$#b; $i++) {
        if ($a[$i] == $b[$i]) {
            $indx[$i] = $i;
        } else {
            $sorted = 0;
            $indx[$i] = &list_match($a[$i], @b);
        }
    }

#   Test whether any members are repeated
    for ($i=1; $i<=$#a; $i++) {
        $indx[$i] = -1 if (&list_match($a[$i], @a) != $i);
    }

#   Return whether @a is sorted, and an index array that would sort @a.
#   An index equal to -1 marks a member that is a repeat.
    return ($sorted, @indx);
}


sub rearrange_array {
    my ($a_ref, $indx_ref) = @_;
    my ($i, @a, @b, @indx);

    @a    = @{ $a_ref    };
    @indx = @{ $indx_ref };

#   Create array b using members of array a according to an array index
    @b = ();
    for ($i=0; $i<=$#indx; $i++) {
        push (@b, $a[$indx[$i]]) if ($indx[$i] != -1);
    }

    return @b;
}


################################################################################
#
# Basic interface subroutines
#
################################################################################

sub native_optionmenu {
    my ($parent, $varref, $var_init, $command, @optionvals) = @_;
    my ($mb, $menu, $callback);

    $$varref = $optionvals[$var_init];
    $mb = $parent->new_menubutton(
            -textvariable       => $varref,
            -indicatoron        => 1,
            -relief             => 'raised',
            -borderwidth        => 2,
            -highlightthickness => 2,
            -anchor             => 'center',
            -direction          => 'right',
            );
    $menu = $mb->new_menu(-tearoff => 0);
    $mb->configure(-menu => $menu);

    $callback = ref($command) =~ /CODE/ ? [$command] : $command;

    foreach (@optionvals) {
        $menu->add_radiobutton(
            -label    => $_,
            -variable => $varref,
            -command  => [@$callback, $_],
            );
    }
    return $mb;
}


sub open_url {
    my ($url, $parent) = @_;
    my ($platform, $cmd);

    $platform = $^O;
    if ($platform =~ /darwin/) {                 # OS X
        $cmd = "open \"$url\"";

    } elsif ($platform eq 'MSWin32' ||
             $platform eq 'msys'   ) {           # Windows native or MSYS / Git Bash
        $cmd = "start \"\" \"$url\"";

    } elsif ($platform eq 'cygwin') {            # Cygwin
        $cmd = "cmd.exe /c start \"\" \"$url \"";  # Note the required trailing space.

    } else {                                     # assume Freedesktop-compliant OS
        $cmd = "xdg-open \"$url\"";                # includes many Linux distros, PC-BSD, OpenSolaris
    }
    if (system($cmd) != 0) {
        &pop_up_error($parent, "Cannot locate or failed to open default browser.\n"
                             . "Please open $url manually.");
    }
}


sub pop_up_info {
    my ($parent, $msg, $title) = @_;
    $title = "Notice" if (! defined($title) || $title eq "");
    Tkx::tk___messageBox(
        -parent  => $parent,
        -title   => $title,
        -icon    => 'info',
        -message => $msg,
        -type    => 'ok',
        );
}


sub pop_up_error {
    my ($parent, $msg) = @_;
    Tkx::tk___messageBox(
        -parent  => $parent,
        -title   => "Error",
        -icon    => 'error',
        -message => $msg,
        -type    => 'ok',
        );
}


sub pop_up_question {
    my ($parent, $question) = @_;
    Tkx::tk___messageBox(
        -parent  => $parent,
        -title   => "Question",
        -icon    => 'question',
        -message => $question,
        -type    => 'yesno',
        );
}


################################################################################
#
# Axis subroutines
#
################################################################################

sub make_axis {
    my ($parent, $canv, %axis_props) = @_;
    my (
        $add_minor, $anc, $ang, $axmax, $axmin, $clipmax, $clipmin, $d, $d1,
        $d2, $d3, $fac, $family, $first, $fmt, $gr1, $gr2, $grcolor, $grid,
        $gridtags, $grwidth, $i, $id, $label, $label_size, $label_weight,
        $labels, $major, $min_major, $minor, $nt, $op_loc, $op_tags,
        $op_tics, $orient, $power, $pr_tics, $range, $reverse, $side,
        $tag, $tags, $title, $title_size, $title_weight, $tmp, $tsize,
        $x1, $x2, $xp1, $xp1o, $xp2, $xp2o, $xp3, $xp4, $xp4o, $xp5, $xp5o,
        $y1, $y2, $yp1, $yp1o, $yp2, $yp2o, $yp3, $yp4, $yp4o, $yp5, $yp5o,

        @coords, @taglist,
       );

    $family       = $axis_props{font};
    $label_size   = $axis_props{size1};
    $title_size   = $axis_props{size2};
    $label_weight = $axis_props{weight1};
    $title_weight = $axis_props{weight2};

    $labels  = 1;
    $clipmin = $clipmax = 0;

    $axmin   = $axis_props{min};
    $axmax   = $axis_props{max};
    $clipmin = $axis_props{clipmin} if (defined($axis_props{clipmin}));
    $clipmax = $axis_props{clipmax} if (defined($axis_props{clipmax}));
    $first   = $axis_props{first}   if (defined($axis_props{first}));
    $major   = $axis_props{major};
    $minor   = $axis_props{minor};     # 0 = no, 1 = yes
    $reverse = $axis_props{reverse};   # 0 = no, 1 = yes
    $title   = $axis_props{title};
    $side    = $axis_props{side};      # left, right, top, bottom
    $pr_tics = $axis_props{pr_tics};   # primary side:   inside, outside, cross, none
    $op_tics = $axis_props{op_tics};   # opposite side:  inside, outside, cross, none
    $op_loc  = $axis_props{op_loc};    # opposite side coordinate
    $tags    = $axis_props{tags};
    $labels  = $axis_props{labels} if (defined($axis_props{labels}));

    if (defined($axis_props{grid})) {
        $grid        = $axis_props{grid};
        $grwidth     = $axis_props{grwidth};
        $grcolor     = $axis_props{grcolor};
        ($gr1, $gr2) = @{ $axis_props{grcoord} };
        ($gridtags = $tags) =~ s/_.axis$/_grid/;
    } else {
        $grid = 0;
    }
    if ($op_tics ne "none") {
        $op_tags = $tags;
        @taglist = split(/ /, $op_tags);
        foreach $tag (@taglist) {
            if ($tag =~ /_.axis$/) {
                $op_tags .= " " . $tag . "2";
                last;
            }
        }
    }
    $title =~ s/^"//;
    $title =~ s/"$//;
    $tsize =  0;

    ($x1, $y1, $x2, $y2) = @{ $axis_props{coords} };

    if ($axmin > $axmax) {
        $axmin = $axis_props{max};
        $axmax = $axis_props{min};
    } elsif ($axmin == $axmax) {
        &pop_up_error($parent, "Axis minimum and maximum values are identical");
        return;
    }
    if ($reverse) {
        $first = $axmax if (! defined($first) || $first eq "");
    } else {
        $first = $axmin if (! defined($first) || $first eq "");
    }
    if ($major ne "auto") {
        $major *= -1     if ($major+0  < 0);
        $major  = "auto" if ($major+0 == 0);
    }
    $minor *= -1 if ($minor < 0);
    if ($y1 == $y2) {
        $orient = "horizontal";
        $side   = "bottom" if (! defined($side) || $side ne "top");
    } elsif ($x1 == $x2) {
        $orient = "vertical";
        $side   = "left" if (! defined($side) || $side ne "right");
    } else {
        &pop_up_error($parent, "Invalid coordinates for axis");
        return;
    }
    if ($op_tics ne "none") {
        if ($orient eq "horizontal") {
            $op_tics = "none" if ($op_loc == $y1 || ($side eq "bottom" && $op_loc > $y1)
                                                 || ($side eq "top"    && $op_loc < $y1));
        } else {
            $op_tics = "none" if ($op_loc == $x1 || ($side eq "left"  && $op_loc < $x1)
                                                 || ($side eq "right" && $op_loc > $x1));
        }
    }

#   Determine an optimal major tick spacing, if needed
    if ($major eq "auto") {
        $range  = $axmax-$axmin;
        $power  = (&log10($range) < 1) ? abs(&floor(&log10($range))) +1 : 0;
        $range *= 10**$power;
        if ($orient eq "horizontal") {
            $min_major = int($range *($label_size *3) /abs($x2-$x1) +0.0000001);
        } else {
            $min_major = int($range *($label_size *3) /abs($y2-$y1) +0.0000001);
        }
        $min_major = 1 if ($min_major == 0);
        for ($i=$min_major; $i<=$range/5; $i++) {
            $major = $i /(10**$power) if (&round_to_int($range) % $i == 0);
        }
        $major = $min_major /(10**$power) if ($major eq "auto");
    }

#   Determine an optimal number of digits after decimal
    $d   = 0;
    $fac = 1;
    $tmp = $major;
    until (abs($tmp*$fac - int($tmp*$fac)) < 0.00001 || $d == 3) {
        $d++;
        $fac = (10**$d);
    }
    $tmp = abs($first);
    until (abs($tmp*$fac - int($tmp*$fac)) < 0.00001 || $d == 3) {
        $d++;
        $fac = (10**$d);
    }
    $fmt = ($d == 0) ? "%d" : "%.${d}f";

#   Make major tick marks and labels
#   Default is increasing value left to right or bottom to top
    $ang = 0;
    if ($orient eq "horizontal") {
        $anc = ($side eq "bottom") ? 'n' : 's';
        $d1  = ($pr_tics eq "cross")       ? 4 : 0;
        $d2  = ($pr_tics eq "inside")      ? 8 : 0;
        $d3  = ($pr_tics =~ /inside|none/) ? 6 : 0;
        $yp1 = ($side eq "bottom") ? $y1-2*$d1   : $y1+2*$d1;   # major ticks
        $yp2 = ($side eq "bottom") ? $y1+8-2*$d2 : $y1-8+2*$d2; # major ticks
        $yp3 = ($side eq "bottom") ? $y1+9-$d3   : $y1-9+$d3;   # tick labels
        $yp4 = ($side eq "bottom") ? $y1-$d1     : $y1+$d1;     # minor ticks
        $yp5 = ($side eq "bottom") ? $y1+4-$d2   : $y1-4+$d2;   # minor ticks
        if ($op_tics ne "none") {
            $d1   = ($op_tics eq "cross")  ? 4 : 0;
            $d2   = ($op_tics eq "inside") ? 8 : 0;
            $yp1o = ($side eq "bottom") ? $op_loc+2*$d1   : $op_loc-2*$d1;   # major ticks
            $yp2o = ($side eq "bottom") ? $op_loc-8+2*$d2 : $op_loc+8-2*$d2; # major ticks
            $yp4o = ($side eq "bottom") ? $op_loc+$d1     : $op_loc-$d1;     # minor ticks
            $yp5o = ($side eq "bottom") ? $op_loc-4+$d2   : $op_loc+4-$d2;   # minor ticks
        }
    } else {
        $anc = ($side eq "left") ? 'e' : 'w';
        $d1  = ($pr_tics eq "cross")       ? 4 : 0;
        $d2  = ($pr_tics eq "inside")      ? 8 : 0;
        $d3  = ($pr_tics =~ /inside|none/) ? 6 : 0;
        $xp1 = ($side eq "left") ? $x1+2*$d1   : $x1-2*$d1;   # major ticks
        $xp2 = ($side eq "left") ? $x1-8+2*$d2 : $x1+8-2*$d2; # major ticks
        $xp3 = ($side eq "left") ? $x1-10+$d3  : $x1+10-$d3;  # tick labels
        $xp4 = ($side eq "left") ? $x1+$d1     : $x1-$d1;     # minor ticks
        $xp5 = ($side eq "left") ? $x1-4+$d2   : $x1+4-$d2;   # minor ticks
        if ($op_tics ne "none") {
            $d1   = ($op_tics eq "cross")  ? 4 : 0;
            $d2   = ($op_tics eq "inside") ? 8 : 0;
            $xp1o = ($side eq "left") ? $op_loc-2*$d1   : $op_loc+2*$d1;   # major ticks
            $xp2o = ($side eq "left") ? $op_loc+8-2*$d2 : $op_loc-8+2*$d2; # major ticks
            $xp4o = ($side eq "left") ? $op_loc-$d1     : $op_loc+$d1;     # minor ticks
            $xp5o = ($side eq "left") ? $op_loc+4-$d2   : $op_loc-4+$d2;   # minor ticks
        }
    }
    if ($reverse) {
        for ($i=$first; $i>=$axmin*0.999999; $i-=$major) {
            $label = sprintf($fmt, $i);
            if ($orient eq "horizontal") {
                $xp1 = $x1 +($x2-$x1)*($axmax-$i)/($axmax-$axmin);
                $xp2 = $xp3 = $xp1o = $xp2o = $xp1;
            } else {
                $yp1 = $y1 +($y2-$y1)*($axmax-$i)/($axmax-$axmin);
                $yp2 = $yp3 = $yp1o = $yp2o = $yp1;
            }
            if ($grid && $i > $axmin && $i < $axmax) {
                if ($orient eq "horizontal") {
                    @coords = ($xp1, $gr1, $xp1, $gr2);
                } else {
                    @coords = ($gr1, $yp1, $gr2, $yp1);
                }
                $canv->create_line(@coords, -fill  => &get_rgb_code($grcolor),
                                            -width => $grwidth,
                                            -arrow => 'none',
                                            -tags  => $gridtags);
            }
            if ($pr_tics ne "none") {
                $canv->create_line($xp1, $yp1, $xp2, $yp2,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $tags);
            }
            if ($op_tics ne "none") {
                $canv->create_line($xp1o, $yp1o, $xp2o, $yp2o,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $op_tags);
            }
            if ($labels && (! $clipmin || $i >= $first -0.98*($first-$axmin)) &&
                           (! $clipmax || $i <= $first -0.02*($first-$axmin))) {
                $id = $canv->create_text($xp3, $yp3,
                                   -anchor => $anc,
                                   -text   => $label,
                                   -fill   => &get_rgb_code("black"),
                                   -angle  => $ang,
                                   -tags   => $tags,
                                   -font   => [-family     => $family,
                                               -size       => $label_size,
                                               -weight     => $label_weight,
                                               -slant      => 'roman',
                                               -underline  => 0,
                                               -overstrike => 0,
                                              ]);
                if ($i >= $first -$major || $i - 2* $major < $axmin) {
                    @coords = Tkx::SplitList($canv->bbox($id));
                    if ($orient eq "horizontal") {
                        $tsize = &max($tsize, abs($coords[3] - $coords[1]));
                    } else {
                        $tsize = &max($tsize, abs($coords[2] - $coords[0]));
                    }
                }
            }
        }
    } else {
        for ($i=$first; $i<=$axmax*1.000001; $i+=$major) {
            $label = sprintf($fmt, $i);
            if ($orient eq "horizontal") {
                $xp1 = $x1 +($x2-$x1)*($i-$axmin)/($axmax-$axmin);
                $xp2 = $xp3 = $xp1o = $xp2o = $xp1;
            } else {
                $yp1 = $y1 +($y2-$y1)*($i-$axmin)/($axmax-$axmin);
                $yp2 = $yp3 = $yp1o = $yp2o = $yp1;
            }
            if ($grid && $i > $axmin && $i < $axmax) {
                if ($orient eq "horizontal") {
                    @coords = ($xp1, $gr1, $xp1, $gr2);
                } else {
                    @coords = ($gr1, $yp1, $gr2, $yp1);
                }
                $canv->create_line(@coords, -fill  => &get_rgb_code($grcolor),
                                            -width => $grwidth,
                                            -arrow => 'none',
                                            -tags  => $gridtags);
            }
            if ($pr_tics ne "none") {
                $canv->create_line($xp1, $yp1, $xp2, $yp2,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $tags);
            }
            if ($op_tics ne "none") {
                $canv->create_line($xp1o, $yp1o, $xp2o, $yp2o,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $op_tags);
            }
            if ($labels && (! $clipmax || $i <= $first +0.98*($axmax-$first)) &&
                           (! $clipmin || $i >= $first +0.02*($axmax-$first))) {
                $id = $canv->create_text($xp3, $yp3,
                                   -anchor => $anc,
                                   -text   => $label,
                                   -fill   => &get_rgb_code("black"),
                                   -angle  => $ang,
                                   -tags   => $tags,
                                   -font   => [-family     => $family,
                                               -size       => $label_size,
                                               -weight     => $label_weight,
                                               -slant      => 'roman',
                                               -underline  => 0,
                                               -overstrike => 0,
                                              ]);
                if ($i <= $first +$major || $i +2* $major > $axmax) {
                    @coords = Tkx::SplitList($canv->bbox($id));
                    if ($orient eq "horizontal") {
                        $tsize = &max($tsize, abs($coords[3] - $coords[1]));
                    } else {
                        $tsize = &max($tsize, abs($coords[2] - $coords[0]));
                    }
                }
            }
        }
    }
    if ($minor != 0 && ($pr_tics ne "none" || $op_tics ne "none")) {
        $nt = int(($axmax - $axmin)/$major +0.00001) +1;
        if ($orient eq "horizontal") {
            $add_minor = (abs($x2-$x1)/$nt > 30) ? 1 : 0;
        } else {
            $add_minor = (abs($y2-$y1)/$nt > 30) ? 1 : 0;
        }
        if ($add_minor) {
            if ($reverse) {
                for ($i=$first-$major/2.; $i>=$axmin; $i-=$major) {
                    if ($orient eq "horizontal") {
                        $xp4 = $x1 +($x2-$x1)*($axmax-$i)/($axmax-$axmin);
                        $xp5 = $xp4o = $xp5o = $xp4;
                    } else {
                        $yp4 = $y1 +($y2-$y1)*($axmax-$i)/($axmax-$axmin);
                        $yp5 = $yp4o = $yp5o = $yp4;
                    }
                    if ($pr_tics ne "none") {
                        $canv->create_line($xp4, $yp4, $xp5, $yp5,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $tags);
                    }
                    if ($op_tics ne "none") {
                        $canv->create_line($xp4o, $yp4o, $xp5o, $yp5o,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $op_tags);
                    }
                }
            } else {
                for ($i=$first+$major/2.; $i<=$axmax; $i+=$major) {
                    if ($orient eq "horizontal") {
                        $xp4 = $x1 +($x2-$x1)*($i-$axmin)/($axmax-$axmin);
                        $xp5 = $xp4o = $xp5o = $xp4;
                    } else {
                        $yp4 = $y1 +($y2-$y1)*($i-$axmin)/($axmax-$axmin);
                        $yp5 = $yp4o = $yp5o = $yp4;
                    }
                    if ($pr_tics ne "none") {
                        $canv->create_line($xp4, $yp4, $xp5, $yp5,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $tags);
                    }
                    if ($op_tics ne "none") {
                        $canv->create_line($xp4o, $yp4o, $xp5o, $yp5o,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $op_tags);
                    }
                }
            }
        }
    }
    if ($labels && $title ne "") {
        $tags .= "Title";
        if ($orient eq "horizontal") {
            $xp1 = ($x1+$x2)/2.;
            $ang = 0;
            $yp1 = ($side eq "bottom") ? $yp3+$tsize : $yp3-$tsize;
            $anc = ($side eq "bottom") ? 'n' : 's';
        } else {
            $yp1 = ($y1+$y2)/2.;
            $anc = 's';
            $xp1 = ($side eq "left") ? $xp3-2-$tsize : $xp3+2+$tsize;
            $ang = ($side eq "left") ? 90 : 270;
        }
        $canv->create_text($xp1, $yp1,
                           -anchor => $anc,
                           -text   => $title,
                           -fill   => &get_rgb_code("black"),
                           -angle  => $ang,
                           -tags   => $tags,
                           -font   => [-family     => $family,
                                       -size       => $title_size,
                                       -weight     => $title_weight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
    }
}


sub make_seg_axis {
    my ($parent, $canv, %axis_props) = @_;
    my (
        $anc, $ang, $axbase, $axis_tag, $axis_tag2, $axmax, $axmin, $bgrid,
        $bgrcolor, $d1, $d2, $d3, $dx, $dy, $family, $flipped, $gr1, $gr2,
        $grcolor, $grid, $gridtags, $gtag, $i, $id, $item, $label_size,
        $label_weight, $major, $min_major, $minor, $mstart, $nsegs, $op_loc,
        $op_tags, $op_tics, $orient, $pr_tics, $saxis_tag, $saxis_tag2,
        $side, $tag, $tags, $ticloc, $title, $title_size, $title_weight,
        $tsize, $type, $val, $x1, $x2, $xp1, $xp1o, $xp2, $xp2o, $xp3,
        $xp4, $xp4o, $xp5, $xp5o, $xtra, $y1, $y2, $yp1, $yp1o, $yp2,
        $yp2o, $yp3, $yp4, $yp4o, $yp5, $yp5o,

        @coords, @dist, @items, @seglist, @taglist,
       );

    $family       = $axis_props{font};
    $label_size   = $axis_props{size1};
    $title_size   = $axis_props{size2};
    $label_weight = $axis_props{weight1};
    $title_weight = $axis_props{weight2};

    $type    = $axis_props{type};           # above, below, replace
    $axbase  = $axis_props{base};           # km
    $axmin   = $axis_props{min};            # km
    $axmax   = $axis_props{max};            # km
    $major   = $axis_props{major};          # number of segments
    $grid    = $axis_props{grid};           # 0 = no, 1 = yes
    $bgrid   = $axis_props{bgrid};          # 0 = no, 1 = yes
    $title   = $axis_props{title};
    $ticloc  = $axis_props{tic_loc};        # center, upstream edge, downstream edge
    $side    = $axis_props{side};           # bottom, left, top, right
    $pr_tics = $axis_props{pr_tics};        # primary side:   inside, outside, cross, none
    $op_tics = $axis_props{op_tics};        # opposite side:  inside, outside, cross, none
    $op_loc  = $axis_props{op_loc};         # opposite side coordinate
    $tags    = $axis_props{tags};

    @seglist = @{ $axis_props{seglist} };   # list of segments, from ds to us
    @dist    = @{ $axis_props{dist}    };   # distance array in km

    if ($grid || $bgrid) {
        $grcolor     = $axis_props{gridcol} if ($grid);
        $bgrcolor    = $axis_props{bgridcol} if ($bgrid);
        ($gr1, $gr2) = @{ $axis_props{grcoord} };
        ($gridtags = $tags) =~ s/_saxis$/_sgrid/;
    }
    if ($op_tics ne "none") {
        $op_tags = $tags;
        @taglist = split(/ /, $op_tags);
        foreach $tag (@taglist) {
            if ($tag =~ /_saxis$/) {
                $op_tags .= " " . $tag . "2";
                last;
            }
        }
    }
    $title =~ s/^"//;
    $title =~ s/"$//;
    $tsize = 5;
    $dx = $dy = 0;

    ($x1, $y1, $x2, $y2) = @{ $axis_props{coords} };

    if ($axmin > $axmax) {
        $axmin = $axis_props{max};
        $axmax = $axis_props{min};
    } elsif ($axmin == $axmax) {
        &pop_up_error($parent, "Axis minimum and maximum values are identical");
        return;
    }
    $major = "auto" if ($major eq "");
    if ($major ne "auto") {
        $major *= -1     if ($major+0  < 0);
        $major  = "auto" if ($major+0 == 0);
    }
    if ($y1 == $y2) {
        $orient  = "horizontal";
        $side    = "bottom" if (! defined($side) || $side ne "top");
        $flipped = ($x1 > $x2) ? 1 : 0;
    } elsif ($x1 == $x2) {
        $orient  = "vertical";
        $side    = "left" if (! defined($side) || $side ne "right");
        $flipped = ($y1 > $y2) ? 1 : 0;
    } else {
        &pop_up_error($parent, "Invalid coordinates for segment axis");
        return;
    }
    if ($op_tics ne "none") {
        if ($orient eq "horizontal") {
            $op_tics = "none" if ($op_loc == $y1 || ($side eq "bottom" && $op_loc > $y1)
                                                 || ($side eq "top"    && $op_loc < $y1));
        } else {
            $op_tics = "none" if ($op_loc == $x1 || ($side eq "left"  && $op_loc < $x1)
                                                 || ($side eq "right" && $op_loc > $x1));
        }
    }

#   Calculate offset if segment axis is below X axis or left of Y axis
    if ($type eq "below") {
        @taglist = split(/ /, $tags);
        foreach $tag (@taglist) {
            if ($tag =~ /_saxis/) {
                if ($orient eq "horizontal") {
                    ($axis_tag = $tag) =~ s/_saxis/_xaxis/;
                } else {
                    ($axis_tag = $tag) =~ s/_saxis/_yaxis/;
                }
                $axis_tag2 = $axis_tag . "2";
                last;
            }
        }
        @items = Tkx::SplitList($canv->find_withtag($axis_tag));
        foreach $item (@items) {
            @taglist = Tkx::SplitList($canv->gettags($item));
            next if (&list_search($axis_tag2, @taglist) >= 0);
            $canv->addtag('group_axis', withtag => $item);
        }
        $canv->addtag('group_axis', withtag => $axis_tag . "Title");
        @coords = Tkx::SplitList($canv->bbox('group_axis'));
        $canv->dtag('group_axis');
        if ($orient eq "horizontal") {
            $dx = 0;
            if ($side eq "bottom") {
                $dy  = &max($coords[3], $coords[1]) -$y1 +7;
                $dy += 8 if ($pr_tics =~ /inside|cross/);
            } else {
                $dy  = &min($coords[3], $coords[1]) -$y1 -7;
                $dy -= 8 if ($pr_tics =~ /inside|cross/);
            }
        } else {
            $dy = 0;
            if ($side eq "left") {
                $dx  = &min($coords[2], $coords[0]) -$x1 -7;
                $dx -= 8 if ($pr_tics =~ /inside|cross/);
            } else {
                $dx  = &max($coords[2], $coords[0]) -$x1 +7;
                $dx += 8 if ($pr_tics =~ /inside|cross/);
            }
        }

      # Make an axis bar
        $canv->create_line($x1+$dx, $y1+$dy, $x2+$dx, $y2+$dy,
                           -fill  => &get_rgb_code("black"),
                           -width => 1,
                           -arrow => 'none',
                           -tags  => $tags);
    }

#   Figure out major spacing if set to "auto"
    $nsegs = $#seglist +1;
    if ($major eq "auto") {
        if ($orient eq "horizontal") {
            $min_major = int($nsegs *($label_size *4) /abs($x2-$x1) +0.0000001);
        } else {
            $min_major = int($nsegs *($label_size *4) /abs($y2-$y1) +0.0000001);
        }
        $major = &max(1, $min_major);
    }

#   Figure out minor spacing
    $minor = 0;
    if ($major > 1) {
        if ($major <= 5) {
            $minor = 1;
        } else {
            $mstart = &round_to_int($major /3.);
            for ($i=$mstart; $i<=$major; $i++) {
                if ($major % $i == 0) {
                    $minor = $i;
                    last;
                }
            }
            $minor = 0 if ($minor == $major);
        }
    }

#   Calculate locations of tick marks and labels
    $ang = 0;
    if ($orient eq "horizontal") {
        $anc = ($side eq "bottom") ? 'n' : 's';
        if ($ticloc =~ /down|up/) {
            if ($ticloc =~ /down/) {
                $xtra = ($flipped) ? 'e': 'w';
            } else {
                $xtra = ($flipped) ? 'w': 'e';
            }
            $anc .= $xtra;
        }
        $d1  = ($pr_tics eq "cross")       ? 4 : 0;
        $d2  = ($pr_tics eq "inside")      ? 8 : 0;
        $d3  = ($pr_tics =~ /inside|none/) ? 6 : 0;
        $yp1 = ($side eq "bottom") ? $y1-2*$d1   : $y1+2*$d1;   # major ticks
        $yp2 = ($side eq "bottom") ? $y1+8-2*$d2 : $y1-8+2*$d2; # major ticks
        $yp3 = ($side eq "bottom") ? $y1+9-$d3   : $y1-9+$d3;   # tick labels
        $yp4 = ($side eq "bottom") ? $y1-$d1     : $y1+$d1;     # minor ticks
        $yp5 = ($side eq "bottom") ? $y1+4-$d2   : $y1-4+$d2;   # minor ticks
        if ($op_tics ne "none") {
            $d1   = ($op_tics eq "cross")  ? 4 : 0;
            $d2   = ($op_tics eq "inside") ? 8 : 0;
            $yp1o = ($side eq "bottom") ? $op_loc+2*$d1   : $op_loc-2*$d1;   # major ticks
            $yp2o = ($side eq "bottom") ? $op_loc-8+2*$d2 : $op_loc+8-2*$d2; # major ticks
            $yp4o = ($side eq "bottom") ? $op_loc+$d1     : $op_loc-$d1;     # minor ticks
            $yp5o = ($side eq "bottom") ? $op_loc-4+$d2   : $op_loc+4-$d2;   # minor ticks
        }
    } else {
        $anc = ($side eq "left") ? 'e' : 'w';
        if ($ticloc =~ /down|up/) {
            if ($ticloc =~ /down/) {
                $xtra = ($flipped) ? 'n': 's';
            } else {
                $xtra = ($flipped) ? 's': 'n';
            }
            $anc = $xtra . $anc;
        }
        $d1  = ($pr_tics eq "cross")       ? 4 : 0;
        $d2  = ($pr_tics eq "inside")      ? 8 : 0;
        $d3  = ($pr_tics =~ /inside|none/) ? 6 : 0;
        $xp1 = ($side eq "left") ? $x1+2*$d1   : $x1-2*$d1;   # major ticks
        $xp2 = ($side eq "left") ? $x1-8+2*$d2 : $x1+8-2*$d2; # major ticks
        $xp3 = ($side eq "left") ? $x1-10+$d3  : $x1+10-$d3;  # tick labels
        $xp4 = ($side eq "left") ? $x1+$d1     : $x1-$d1;     # minor ticks
        $xp5 = ($side eq "left") ? $x1-4+$d2   : $x1+4-$d2;   # minor ticks
        if ($op_tics ne "none") {
            $d1   = ($op_tics eq "cross")  ? 4 : 0;
            $d2   = ($op_tics eq "inside") ? 8 : 0;
            $xp1o = ($side eq "left") ? $op_loc-2*$d1   : $op_loc+2*$d1;   # major ticks
            $xp2o = ($side eq "left") ? $op_loc+8-2*$d2 : $op_loc-8+2*$d2; # major ticks
            $xp4o = ($side eq "left") ? $op_loc-$d1     : $op_loc+$d1;     # minor ticks
            $xp5o = ($side eq "left") ? $op_loc+4-$d2   : $op_loc-4+$d2;   # minor ticks
        }
    }

#   Make grid lines, if requested
    if ($grid) {
        for ($i=$#seglist; $i>=0; $i-=$major) {
            if ($ticloc eq "upstream edge") {
                $val = $dist[$seglist[$i]];
            } elsif ($ticloc eq "downstream edge") {
                $val = ($i == 0) ? 0.0 : $dist[$seglist[$i-1]];
            } else {
                $val = ($i == 0) ? 0.5*$dist[$seglist[$i]] : 0.5*($dist[$seglist[$i]] +$dist[$seglist[$i-1]]);
            }
            $val += $axbase;
            next if ($val < $axmin -0.001 || $val > $axmax +0.001);
            if ($orient eq "horizontal") {
                $xp1 = $x1 +($x2-$x1)*($val-$axmin)/($axmax-$axmin);
                @coords = ($xp1, $gr1, $xp1, $gr2);
            } else {
                $yp1 = $y1 +($y2-$y1)*($val-$axmin)/($axmax-$axmin);
                @coords = ($gr1, $yp1, $gr2, $yp1);
            }
            $canv->create_line(@coords, -fill  => &get_rgb_code($grcolor),
                                        -width => 1,
                                        -arrow => 'none',
                                        -tags  => $gridtags);
        }
    }

#   Make branch boundary grid lines, if requested
    if ($bgrid) {
        for ($i=$#seglist; $i>0; $i--) {
            next if ($seglist[$i-1] == $seglist[$i] +1);
            $val  = $dist[$seglist[$i-1]];
            $val += $axbase;
            next if ($val < $axmin || $val > $axmax);
            if ($orient eq "horizontal") {
                $xp1 = $x1 +($x2-$x1)*($val-$axmin)/($axmax-$axmin);
                @coords = ($xp1, $gr1, $xp1, $gr2);
            } else {
                $yp1 = $y1 +($y2-$y1)*($val-$axmin)/($axmax-$axmin);
                @coords = ($gr1, $yp1, $gr2, $yp1);
            }
            $canv->create_line(@coords, -fill  => &get_rgb_code($bgrcolor),
                                        -width => 1,
                                        -arrow => 'none',
                                        -tags  => $gridtags);
        }
    }

#   Make major tick marks and labels
    for ($i=$#seglist; $i>=0; $i-=$major) {
        if ($ticloc eq "upstream edge") {
            $val = $dist[$seglist[$i]];
        } elsif ($ticloc eq "downstream edge") {
            $val = ($i == 0) ? 0.0 : $dist[$seglist[$i-1]];
        } else {
            $val = ($i == 0) ? 0.5* $dist[$seglist[$i]] : 0.5* ($dist[$seglist[$i]] +$dist[$seglist[$i-1]]);
        }
        $val += $axbase;
        next if ($val < $axmin -0.001 || $val > $axmax +0.001);
        if ($orient eq "horizontal") {
            $xp1 = $x1 +($x2-$x1)*($val-$axmin)/($axmax-$axmin);
            $xp2 = $xp3 = $xp1o = $xp2o = $xp1;
        } else {
            $yp1 = $y1 +($y2-$y1)*($val-$axmin)/($axmax-$axmin);
            $yp2 = $yp3 = $yp1o = $yp2o = $yp1;
        }
        if ($pr_tics ne "none") {
            $canv->create_line($xp1+$dx, $yp1+$dy, $xp2+$dx, $yp2+$dy,
                               -fill  => &get_rgb_code("black"),
                               -width => 1,
                               -arrow => 'none',
                               -tags  => $tags);
        }
        if ($op_tics ne "none") {
            $canv->create_line($xp1o, $yp1o, $xp2o, $yp2o,
                               -fill  => &get_rgb_code("black"),
                               -width => 1,
                               -arrow => 'none',
                               -tags  => $op_tags);
        }
        $id = $canv->create_text($xp3+$dx, $yp3+$dy,
                           -anchor => $anc,
                           -text   => $seglist[$i],
                           -fill   => &get_rgb_code("black"),
                           -angle  => $ang,
                           -tags   => $tags,
                           -font   => [-family     => $family,
                                       -size       => $label_size,
                                       -weight     => $label_weight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
        @coords = Tkx::SplitList($canv->bbox($id));
        if ($orient eq "horizontal") {
            $tsize = &max($tsize, abs($coords[3] - $coords[1]));
        } else {
            $tsize = &max($tsize, abs($coords[2] - $coords[0]));
        }
    }

#   Make minor tick marks
    if ($minor > 0 && ($pr_tics ne "none" || $op_tics ne "none")) {
        for ($i=$#seglist; $i>=0; $i-=$minor) {
            next if (($#seglist-$i) % $major == 0);
            if ($ticloc eq "upstream edge") {
                $val = $dist[$seglist[$i]];
            } elsif ($ticloc eq "downstream edge") {
                $val = ($i==0) ? 0.0 : $dist[$seglist[$i-1]];
            } else {
                $val = ($i==0) ? 0.5* $dist[$seglist[$i]] : 0.5* ($dist[$seglist[$i]] +$dist[$seglist[$i-1]]);
            }
            $val += $axbase;
            next if ($val < $axmin -0.0005 || $val > $axmax +0.0005);
            if ($orient eq "horizontal") {
                $xp4 = $x1 +($x2-$x1)*($val-$axmin)/($axmax-$axmin);
                $xp5 = $xp4o = $xp5o = $xp4;
            } else {
                $yp4 = $y1 +($y2-$y1)*($val-$axmin)/($axmax-$axmin);
                $yp5 = $yp4o = $yp5o = $yp4;
            }
            if ($pr_tics ne "none") {
                $canv->create_line($xp4+$dx, $yp4+$dy, $xp5+$dx, $yp5+$dy,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $tags);
            }
            if ($op_tics ne "none") {
                $canv->create_line($xp4o, $yp4o, $xp5o, $yp5o,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $op_tags);
            }
        }
    }

#   Segment axis title
    if ($title ne "") {
        $tags .= "Title";
        $d3    = ($pr_tics =~ /inside|none/) ? 6 : 0;
        if ($orient eq "horizontal") {
            $xp1 = ($x1+$x2)/2.;
            $ang = 0;
            $yp1 = ($side eq "bottom") ? $y1+9+$tsize-$d3 : $y1-9-$tsize+$d3;
            $anc = ($side eq "bottom") ? 'n' : 's';
        } else {
            $yp1 = ($y1+$y2)/2.;
            $anc = 's';
            $xp1 = ($side eq "left") ? $x1-12-$tsize+$d3 : $x1+12+$tsize-$d3;
            $ang = ($side eq "left") ? 90 : 270;
        }
        $canv->create_text($xp1+$dx, $yp1+$dy,
                           -anchor => $anc,
                           -text   => $title,
                           -fill   => &get_rgb_code("black"),
                           -angle  => $ang,
                           -tags   => $tags,
                           -font   => [-family     => $family,
                                       -size       => $title_size,
                                       -weight     => $title_weight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
    }

#   Move the regular axis if segment axis is above the regular axis.
#   At this point, the segment axis is restricted to orient=horizontal and side=bottom
#     and therefore the regular axis is the X axis.
    if ($type eq "above") {
        @taglist = split(/ /, $tags);
        foreach $tag (@taglist) {
            if ($tag =~ /_saxis/) {
                ($saxis_tag = $tag) =~ s/Title$//;
                if ($orient eq "horizontal") {
                    ($axis_tag = $saxis_tag) =~ s/_saxis/_xaxis/;
                } else {
                    ($axis_tag = $saxis_tag) =~ s/_saxis/_yaxis/;
                }
                $saxis_tag2 = $saxis_tag . "2";
                $axis_tag2  = $axis_tag  . "2";
                last;
            }
        }
      # Get bounding box for segment axis, tick, and title without opposite axis
        @items = Tkx::SplitList($canv->find_withtag($saxis_tag));
        foreach $item (@items) {
            @taglist = Tkx::SplitList($canv->gettags($item));
            next if (&list_search($saxis_tag2, @taglist) >= 0);
            $canv->addtag('group_axis', withtag => $item);
        }
        $canv->addtag('group_axis', withtag => $saxis_tag . "Title");
        @coords = Tkx::SplitList($canv->bbox('group_axis'));
        $canv->dtag('group_axis');
        if ($orient eq "horizontal") {
            $dx = 0;
            if ($side eq "bottom") {
                $dy = &max($coords[3], $coords[1]) -$y1 +7;
            } else {
                $dy = &min($coords[3], $coords[1]) -$y1 -7;
            }
        } else {
            $dy = 0;
            if ($side eq "left") {
                $dx = &min($coords[2], $coords[0]) -$x1 -7;
            } else {
                $dx = &max($coords[2], $coords[0]) -$x1 +7;
            }
        }
      # Get bounding box for regular axis, tick, and title without opposite axis
        @items = Tkx::SplitList($canv->find_withtag($axis_tag));
        foreach $item (@items) {
            @taglist = Tkx::SplitList($canv->gettags($item));
            next if (&list_search($axis_tag2, @taglist) >= 0);
            $canv->addtag('group_axis', withtag => $item);
        }
        $canv->addtag('group_axis', withtag => $axis_tag . "Title");
        @coords = Tkx::SplitList($canv->bbox('group_axis'));
        if ($orient eq "horizontal") {
            if ($side eq "bottom") {
                $dy += &max(0, $y1-&min($coords[3], $coords[1]));
            } else {
                $dy -= &max(0, &max($coords[3], $coords[1]) -$y1);
            }
        } else {
            if ($side eq "left") {
                $dx -= &max(0, &max($coords[2], $coords[0]) -$x1);
            } else {
                $dx += &max(0, $x1-&min($coords[2], $coords[0]));
            }
        }
        $canv->move('group_axis', $dx, $dy);
        $canv->dtag('group_axis');

      # Add an axis line for the regular axis
        ($gtag = $axis_tag) =~ s/_.axis//;
        $tags = $gtag . " " . $axis_tag;
        $canv->create_line($x1+$dx, $y1+$dy, $x2+$dx, $y2+$dy,
                           -fill  => &get_rgb_code("black"),
                           -width => 1,
                           -arrow => 'none',
                           -tags  => $tags);
    }
}


sub make_date_axis {
    my ($parent, $canv, %axis_props) = @_;
    my (

        $add_minor, $anc, $ang, $ax_pix, $axmax, $axmin, $d, $d1, $d2, $d3,
        $datefmt, $family, $fmt, $gr1, $gr2, $grcolor, $grid, $gridtags,
        $grwidth, $i, $id, $jd, $label, $label_size, $label_weight, $m,
        $major, $min_major, $minor, $next_jd, $nt, $on_tick, $op_loc,
        $op_tags, $op_tics, $orient, $pix_per_mon, $pix_per_yr, $pr_tics,
        $range, $reverse, $side, $tag, $tags, $title, $title_size,
        $title_weight, $tsize, $x1, $x2, $xp1, $xp1o, $xp2, $xp2o, $xp3,
        $xp4, $xp4o, $xp5, $xp5o, $xtra, $y, $y1, $y2, $yp1, $yp1o, $yp2,
        $yp2o, $yp3, $yp4, $yp4o, $yp5, $yp5o, $yr_max, $yr_min,

        @coords, @long_ticks, @major_ticks, @taglist, @tick_jd, @tick_jd2,
        @tick_labels, @tick_labels2,
       );

    $family       = $axis_props{font};
    $label_size   = $axis_props{size1};
    $title_size   = $axis_props{size2};
    $label_weight = $axis_props{weight1};
    $title_weight = $axis_props{weight2};

    $axmin   = $axis_props{min};
    $axmax   = $axis_props{max};
    $major   = $axis_props{major};
    $minor   = $axis_props{minor};     # 0 = no, 1 = yes
    $reverse = $axis_props{reverse};   # 0 = no, 1 = yes
    $datefmt = $axis_props{datefmt};   # Year, Month, Mon-DD, Mon-DD-YYYY
    $title   = $axis_props{title};
    $side    = $axis_props{side};      # left, right, top, bottom
    $pr_tics = $axis_props{pr_tics};   # primary side:   inside, outside, cross, none
    $op_tics = $axis_props{op_tics};   # opposite side:  inside, outside, cross, none
    $op_loc  = $axis_props{op_loc};    # opposite side coordinate
    $tags    = $axis_props{tags};

    if (defined($axis_props{grid})) {
        $grid        = $axis_props{grid};
        $grwidth     = $axis_props{grwidth};
        $grcolor     = $axis_props{grcolor};
        ($gr1, $gr2) = @{ $axis_props{grcoord} };
        ($gridtags = $tags) =~ s/_.axis$/_grid/;
    } else {
        $grid = 0;
    }
    if ($op_tics ne "none") {
        $op_tags = $tags;
        @taglist = split(/ /, $op_tags);
        foreach $tag (@taglist) {
            if ($tag =~ /_.axis$/) {
                $op_tags .= " " . $tag . "2";
                last;
            }
        }
    }
    $title =~ s/^"//;
    $title =~ s/"$//;
    $tsize =  0;

    ($x1, $y1, $x2, $y2) = @{ $axis_props{coords} };

    if ($axmin > $axmax) {
        $axmin = $axis_props{max};
        $axmax = $axis_props{min};
    } elsif ($axmin == $axmax) {
        &pop_up_error($parent, "Axis minimum and maximum values are identical");
        return;
    }
    if ($major ne "auto") {
        $major *= -1     if ($major+0  < 0);
        $major  = "auto" if ($major+0 == 0);
    }
    $minor *= -1 if ($minor < 0);
    if ($y1 == $y2) {
        $orient = "horizontal";
        $side   = "bottom" if (! defined($side) || $side ne "top");
        $ax_pix = abs($x2-$x1);
    } elsif ($x1 == $x2) {
        $orient = "vertical";
        $side   = "left" if (! defined($side) || $side ne "right");
        $ax_pix = abs($y2-$y1);
    } else {
        &pop_up_error($parent, "Invalid coordinates for axis");
        return;
    }
    if ($op_tics ne "none") {
        if ($orient eq "horizontal") {
            $op_tics = "none" if ($op_loc == $y1 || ($side eq "bottom" && $op_loc > $y1)
                                                 || ($side eq "top"    && $op_loc < $y1));
        } else {
            $op_tics = "none" if ($op_loc == $x1 || ($side eq "left"  && $op_loc < $x1)
                                                 || ($side eq "right" && $op_loc > $x1));
        }
    }

#   Determine an optimal major tick spacing for date axis
    $xtra    = 0;
    $on_tick = 0;
    @major_ticks  = ();
    @long_ticks   = ();
    @tick_jd      = ();
    @tick_jd2     = ();
    @tick_labels  = ();
    @tick_labels2 = ();
    if ($datefmt eq "Year") {
        $fmt = $datefmt;
        if ($orient eq "horizontal") {
            $ang = 0;
            $anc = ($side eq "bottom") ? 'n' : 's';
        } else {
            $ang = 90;
            $anc = ($side eq "left") ? 's' : 'n';
        }
        $pix_per_yr = $ax_pix /(($axmax-$axmin) /365.25);
        if ($pix_per_yr / $label_size <= 1.5) {    # Year on major tick mark, rotated; use major
            $on_tick = 1;
            if ($orient eq "horizontal") {
                $ang  = 90;
                $anc  = ($side eq "bottom") ? 'e' : 'w';
                $xtra = 2 if ($side eq "bottom");
            } else {
                $ang  = 0;
                $anc  = ($side eq "left") ? 'e' : 'w';
                $xtra = 2 if ($side eq "left");
            }
            ($yr_min, $m, $d) = split(/-/, &jdate2datelabel(&floor($axmin +0.0000001), ""));
            ($yr_max, $m, $d) = split(/-/, &jdate2datelabel($axmax, ""));
            $range = $yr_max -$yr_min;
            if ($major eq "auto") {
                if ($orient eq "horizontal") {
                    $min_major = int($range *($label_size *2.5) /abs($x2-$x1) +0.0000001);
                } else {
                    $min_major = int($range *($label_size *2.5) /abs($y2-$y1) +0.0000001);
                }
                $min_major = 1 if ($min_major == 0);
                for ($i=$range-1; $i>=$min_major; $i--) {
                    $major = $i if ($range % $i == 0);
                }
                $major = $min_major if ($major eq "auto");
            }
            $major = &min($range, $major);
        } elsif ($pix_per_yr /$label_size <= 4) {  # Year between tick marks, rotated
            $on_tick = 0;
            $minor   = 0;
            if ($orient eq "horizontal") {
                $ang  = 90;
                $anc  = ($side eq "bottom") ? 'e' : 'w';
                $xtra = 2 if ($side eq "bottom");
            } else {
                $ang  = 0;
                $anc  = ($side eq "left") ? 'e' : 'w';
                $xtra = 2 if ($side eq "left");
            }
        } else {                                   # Year between ticks, unrotated
            $on_tick = 0;
            $minor   = 0;
        }
        $jd = &floor($axmin +0.0000001);
        ($y, $m, $d) = split(/-/, &jdate2datelabel($jd, ""));
        if ($on_tick) {
            if ($m == 1 && $d == 1) {
                push (@major_ticks, $jd);
                push (@tick_labels, $y);
                $next_jd = &date2jdate(sprintf("%04d%s", $y+$major, "0101"));
                $y += $major;
            } else {
                $next_jd = &date2jdate(sprintf("%04d%s", $y+1, "0101"));
                $y++;
            }
            while ($next_jd <= $axmax) {
                $jd      = $next_jd;
                $next_jd = &date2jdate(sprintf("%04d%s", $y+$major, "0101"));
                if ($jd <= $axmax) {
                    push (@major_ticks, $jd);
                    push (@tick_labels, $y);
                }
                $y += $major;
            }
            @tick_jd = @major_ticks;
        } else {
            $next_jd = &date2jdate(sprintf("%04d%s", $y+1, "0101"));
            if ($m == 1 && $d == 1) {
                push (@major_ticks, $jd);
                push (@tick_labels, $y);
                push (@tick_jd, ($jd + &min($next_jd, $axmax))/2.);
            } elsif ($m <= 6) {
                push (@tick_labels, $y);
                push (@tick_jd, ($jd + &min($next_jd, $axmax))/2.);
            }
            $y++;
            while ($next_jd <= $axmax) {
                push (@major_ticks, $next_jd);
                $jd      = $next_jd;
                $next_jd = &date2jdate(sprintf("%04d%s", $y+1, "0101"));
                if ($next_jd <= $axmax) {
                    push (@tick_labels, $y);
                    push (@tick_jd, ($jd +$next_jd)/2.);
                }
                $y++;
            }
            if ($jd < $axmax) {
                ($y, $m, $d) = split(/-/, &jdate2datelabel($axmax, ""));
                if ($m >= 7) {
                    push (@tick_labels, $y);
                    push (@tick_jd, ($jd +$axmax)/2.);
                }
            }
        }

    } elsif ($datefmt eq "Month") {
        $minor = 0;
        if ($orient eq "horizontal") {
            $ang = 0;
            $anc = ($side eq "bottom") ? 'n' : 's';
        } else {
            $ang = 90;
            $anc = ($side eq "left") ? 's' : 'n';
        }
        $pix_per_mon = $ax_pix /(($axmax-$axmin) *12/365.25);
        if ($pix_per_mon /$label_size >= 8) {
            $fmt = "Month";
            $datefmt = "MonthDay" if (($axmax -$axmin) *1.9 *$label_size < $ax_pix);
        } elsif ($pix_per_mon /$label_size > 4) {
            $fmt = "Mon";
        } elsif ($pix_per_mon /$label_size > 1.5) {
            $fmt = "Mon";
            if ($orient eq "horizontal") {
                $ang  = 90;
                $anc  = ($side eq "bottom") ? 'e' : 'w';
                $xtra = 2 if ($side eq "bottom");
            } else {
                $ang  = 0;
                $anc  = ($side eq "left") ? 'e' : 'w';
                $xtra = 2 if ($side eq "left");
            }
        } else {
            $fmt = "M";
        }
        $jd = &floor($axmin +0.0000001);
        ($y, $m, $d) = split(/-/, &jdate2datelabel($jd, ""));
        push (@major_ticks, $jd) if ($d == 1);
        &set_leap_year($y);
        $next_jd = &min($axmax, $jd -$d +$days_in_month[$m-1] +1);
        if ($fmt eq "Month" && (($datefmt eq "MonthDay" && ($next_jd -$jd) < 10) ||
                                ($datefmt eq "Month"    && ($next_jd -$jd) < 20))) {
            $label = &jdate2datelabel($jd, "Mon");
        } else {
            $label = &jdate2datelabel($jd, $fmt);
        }
        if ($next_jd -$jd >= 17
             || 2 *length($label) *$label_size /$ax_pix < ($next_jd -$jd) /($axmax -$axmin)) {
            push (@tick_jd, ($jd + &min($next_jd, $axmax))/2.);
            push (@tick_labels, $label);
        }
        $next_jd = $jd -$d +$days_in_month[$m-1] +1;
        while ($next_jd <= $axmax) {
            $jd = $next_jd;
            push (@major_ticks, $jd);
            $m++;
            if ($m > 12) {
                $m = 1;
                $y++;
                &set_leap_year($y);
            }
            $next_jd = $jd +$days_in_month[$m-1];
            if ($next_jd <= $axmax) {
                push (@tick_jd,     ($jd +$next_jd)/2.);
                push (@tick_labels, &jdate2datelabel($jd, $fmt));
            }
        }
        if ($jd < $axmax) {
            ($y, $m, $d) = split(/-/, &jdate2datelabel($axmax, ""));
            if ($fmt eq "Month" && (($datefmt eq "MonthDay" && $d < 10) ||
                                    ($datefmt eq "Month"    && $d < 20))) {
                $label = &jdate2datelabel($jd, "Mon");
            } else {
                $label = &jdate2datelabel($jd, $fmt);
            }
            if ($d >= 17 || 2 *length($label) *$label_size /$ax_pix < ($d-1) /($axmax -$axmin)) {
                push (@tick_jd, ($jd +$axmax)/2.);
                push (@tick_labels, $label);
            }
        }
        if ($#tick_jd > 0 && $tick_jd[-1] == $tick_jd[-2]) {
            pop (@tick_jd);
            $tick_labels[-1] = pop (@tick_labels);
        }
        if ($datefmt eq "MonthDay") {
            @tick_jd2     = @tick_jd;
            @tick_labels2 = @tick_labels;
            for ($i=0; $i<=$#tick_jd2; $i++) {
                ($y, $m, $d) = split(/-/, &jdate2datelabel($tick_jd2[$i], ""));
                $tick_labels2[$i] .= ", $y";
            }
            @major_ticks = ();
            @tick_jd     = ();
            @tick_labels = ();
            $title = "" if ($#tick_labels2 >= 0);
            $jd    = &floor($axmin +0.0000001);
            ($y, $m, $d) = split(/-/, &jdate2datelabel($jd, ""));
            &set_leap_year($y);
            if ($d == 1) {
                push (@long_ticks, $jd);
            } else {
                push (@major_ticks, $jd);
            }
            while ($jd +1 <= $axmax) {
                push (@tick_jd,     $jd +0.5);
                push (@tick_labels, sprintf("%d", $d));
                $jd++;
                $d++;
                if ($d > $days_in_month[$m-1]) {
                    $d = 1;
                    $m++;
                    if ($m > 12) {
                        $m = 1;
                        $y++;
                        &set_leap_year($y);
                    }
                }
                if ($d == 1) {
                    push (@long_ticks, $jd);
                } else {
                    push (@major_ticks, $jd);
                }
            }
        }

    } else {                           # Mon-DD or Mon-DD-YYYY format
        $fmt = $datefmt;
        if ($orient eq "horizontal") {
            $ang  = 90;
            $anc  = ($side eq "bottom") ? 'e' : 'w';
            $xtra = 2 if ($side eq "bottom");
        } else {
            $ang  = 0;
            $anc  = ($side eq "left") ? 'e' : 'w';
            $xtra = 2 if ($side eq "left");
        }
        if ($major eq "auto") {
            $range = $axmax-$axmin;
            if ($orient eq "horizontal") {
                $min_major = int($range *($label_size *3) /abs($x2-$x1) +0.0000001);
            } else {
                $min_major = int($range *($label_size *3) /abs($y2-$y1) +0.0000001);
            }
            $min_major = 1 if ($min_major == 0);
            for ($i=$min_major; $i<=$range/12; $i++) {
                $major = $i if (&round_to_int($range) % $i == 0);
            }
            $major = $min_major if ($major eq "auto");
        }
        if ($reverse) {
            for ($i=$axmax; $i<=$axmin; $i-=$major) {
                push (@major_ticks, $i);
                push (@tick_labels, &jdate2datelabel($i, $fmt));
            }
        } else {
            for ($i=$axmin; $i<=$axmax; $i+=$major) {
                push (@major_ticks, $i);
                push (@tick_labels, &jdate2datelabel($i, $fmt));
            }
        }
        @tick_jd = @major_ticks;
    }

#   Make major tick marks and labels
    if ($orient eq "horizontal") {
        $d1  = ($pr_tics eq "cross")       ? 4 : 0;
        $d2  = ($pr_tics eq "inside")      ? 8 : 0;
        $d3  = ($pr_tics =~ /inside|none/) ? 6 : 0;
        $yp1 = ($side eq "bottom") ? $y1-2*$d1   : $y1+2*$d1;                # major ticks
        $yp2 = ($side eq "bottom") ? $y1+8-2*$d2 : $y1-8+2*$d2;              # major ticks
        $yp4 = ($side eq "bottom") ? $y1-$d1     : $y1+$d1;                  # minor ticks
        $yp5 = ($side eq "bottom") ? $y1+4-$d2   : $y1-4+$d2;                # minor ticks
        if ($fmt =~ /^(Month|Mon|M)$/ || ($fmt eq "Year" && ! $on_tick)) {
            $yp3 = ($side eq "bottom") ? $y1+5-(2/6*$d3)+$xtra : $y1-5+(2/6*$d3)-$xtra;
        } else {
            $yp3 = ($side eq "bottom") ? $y1+9-$d3+$xtra : $y1-9+$d3-$xtra;  # tick marks
        }
        if ($op_tics ne "none") {
            $d1   = ($op_tics eq "cross")  ? 4 : 0;
            $d2   = ($op_tics eq "inside") ? 8 : 0;
            $yp1o = ($side eq "bottom") ? $op_loc+2*$d1   : $op_loc-2*$d1;   # major ticks
            $yp2o = ($side eq "bottom") ? $op_loc-8+2*$d2 : $op_loc+8-2*$d2; # major ticks
            $yp4o = ($side eq "bottom") ? $op_loc+$d1     : $op_loc-$d1;     # minor ticks
            $yp5o = ($side eq "bottom") ? $op_loc-4+$d2   : $op_loc+4-$d2;   # minor ticks
        }
    } else {
        $d1  = ($pr_tics eq "cross")       ? 4 : 0;
        $d2  = ($pr_tics eq "inside")      ? 8 : 0;
        $d3  = ($pr_tics =~ /inside|none/) ? 6 : 0;
        $xp1 = ($side eq "left") ? $x1+2*$d1   : $x1-2*$d1;   # major ticks
        $xp2 = ($side eq "left") ? $x1-8+2*$d2 : $x1+8-2*$d2; # major ticks
        $xp4 = ($side eq "left") ? $x1+$d1     : $x1-$d1;     # minor ticks
        $xp5 = ($side eq "left") ? $x1-4+$d2   : $x1+4-$d2;   # minor ticks
        if ($fmt =~ /^(Month|Mon|M)$/ || ($fmt eq "Year" && ! $on_tick)) {
            $xp3 = ($side eq "left") ? $x1-5+(2/6*$d3)-$xtra : $x1+5-(2/6*$d3)+$xtra;
        } else {
            $xp3 = ($side eq "left") ? $x1-9+$d3-$xtra : $x1+9-$d3+$xtra;
        }
        if ($op_tics ne "none") {
            $d1   = ($op_tics eq "cross")  ? 4 : 0;
            $d2   = ($op_tics eq "inside") ? 8 : 0;
            $xp1o = ($side eq "left") ? $op_loc-2*$d1   : $op_loc+2*$d1;   # major ticks
            $xp2o = ($side eq "left") ? $op_loc+8-2*$d2 : $op_loc-8+2*$d2; # major ticks
            $xp4o = ($side eq "left") ? $op_loc-$d1     : $op_loc+$d1;     # minor ticks
            $xp5o = ($side eq "left") ? $op_loc+4-$d2   : $op_loc-4+$d2;   # minor ticks
        }
    }
    if ($grid || $pr_tics ne "none" || $op_tics ne "none") {
        for ($i=0; $i<=$#major_ticks; $i++) {
            $jd = $major_ticks[$i];
            if ($reverse) {
                if ($orient eq "horizontal") {
                    $xp1 = $x1 +($x2-$x1)*($axmax-$jd)/($axmax-$axmin);
                    $xp2 = $xp1o = $xp2o = $xp1;
                } else {
                    $yp1 = $y1 +($y2-$y1)*($axmax-$jd)/($axmax-$axmin);
                    $yp2 = $yp1o = $yp2o = $yp1;
                }
            } else {
                if ($orient eq "horizontal") {
                    $xp1 = $x1 +($x2-$x1)*($jd-$axmin)/($axmax-$axmin);
                    $xp2 = $xp1o = $xp2o = $xp1;
                } else {
                    $yp1 = $y1 +($y2-$y1)*($jd-$axmin)/($axmax-$axmin);
                    $yp2 = $yp1o = $yp2o = $yp1;
                }
            }
            if ($grid && $jd > $axmin && $jd < $axmax) {
                if ($orient eq "horizontal") {
                    @coords = ($xp1, $gr1, $xp1, $gr2);
                } else {
                    @coords = ($gr1, $yp1, $gr2, $yp1);
                }
                $canv->create_line(@coords, -fill  => &get_rgb_code($grcolor),
                                            -width => $grwidth,
                                            -arrow => 'none',
                                            -tags  => $gridtags);
            }
            if ($pr_tics ne "none") {
                $canv->create_line($xp1, $yp1, $xp2, $yp2,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $tags);
            }
            if ($op_tics ne "none") {
                $canv->create_line($xp1o, $yp1o, $xp2o, $yp2o,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $op_tags);
            }
        }
    }
    for ($i=0; $i<=$#tick_jd; $i++) {
        $jd    = $tick_jd[$i];
        $label = $tick_labels[$i];
        if ($reverse) {
            if ($orient eq "horizontal") {
                $xp3 = $x1 +($x2-$x1)*($axmax-$jd)/($axmax-$axmin);
            } else {
                $yp3 = $y1 +($y2-$y1)*($axmax-$jd)/($axmax-$axmin);
            }
        } else {
            if ($orient eq "horizontal") {
                $xp3 = $x1 +($x2-$x1)*($jd-$axmin)/($axmax-$axmin);
            } else {
                $yp3 = $y1 +($y2-$y1)*($jd-$axmin)/($axmax-$axmin);
            }
        }
        $id = $canv->create_text($xp3, $yp3,
                           -anchor => $anc,
                           -text   => $label,
                           -fill   => &get_rgb_code("black"),
                           -angle  => $ang,
                           -tags   => $tags,
                           -font   => [-family     => $family,
                                       -size       => $label_size,
                                       -weight     => $label_weight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
        if ($i == 0 || $i == $#tick_labels) {
            @coords = Tkx::SplitList($canv->bbox($id));
            if ($orient eq "horizontal") {
                $tsize = &max($tsize, abs($coords[3] - $coords[1]));
            } else {
                $tsize = &max($tsize, abs($coords[2] - $coords[0]));
            }
        }
    }
    if ($#long_ticks >= 0 && ($grid || $pr_tics ne "none" || $op_tics ne "none")) {
        if ($orient eq "horizontal") {
            $d1  = ($pr_tics eq "cross")  ? 12 : 0;
            $d2  = ($pr_tics eq "inside") ? 17+$tsize+$xtra : 0;
            $yp1 = ($side eq "bottom") ? $y1-$d1                : $y1+$d1;
            $yp2 = ($side eq "bottom") ? $y1+5+$tsize+$xtra-$d2 : $y1-5-$tsize-$xtra+$d2;
            if ($op_tics ne "none") {
                $d1   = ($op_tics eq "cross")  ? 12 : 0;
                $d2   = ($op_tics eq "inside") ? 24 : 0;
                $yp1o = ($side eq "bottom") ? $op_loc+$d1    : $op_loc-$d1;
                $yp2o = ($side eq "bottom") ? $op_loc-12+$d2 : $op_loc+12-$d2;
            }
        } else {
            $d1  = ($pr_tics eq "cross")  ? 12 : 0;
            $d2  = ($pr_tics eq "inside") ? 22+$tsize : 0;
            $xp1 = ($side eq "left") ? $x1+$d1           : $x1-$d1;
            $xp2 = ($side eq "left") ? $x1-10-$tsize+$d2 : $x1+10+$tsize-$d2;
            if ($op_tics ne "none") {
                $d1   = ($op_tics eq "cross")  ? 12 : 0;
                $d2   = ($op_tics eq "inside") ? 24 : 0;
                $xp1o = ($side eq "left") ? $op_loc-$d1    : $op_loc+$d1;
                $xp2o = ($side eq "left") ? $op_loc+12-$d2 : $op_loc-12+$d2;
            }
        }
        for ($i=0; $i<=$#long_ticks; $i++) {
            $jd = $long_ticks[$i];
            if ($reverse) {
                if ($orient eq "horizontal") {
                    $xp1 = $x1 +($x2-$x1)*($axmax-$jd)/($axmax-$axmin);
                    $xp2 = $xp1o = $xp2o = $xp1;
                } else {
                    $yp1 = $y1 +($y2-$y1)*($axmax-$jd)/($axmax-$axmin);
                    $yp2 = $yp1o = $yp2o = $yp1;
                }
            } else {
                if ($orient eq "horizontal") {
                    $xp1 = $x1 +($x2-$x1)*($jd-$axmin)/($axmax-$axmin);
                    $xp2 = $xp1o = $xp2o = $xp1;
                } else {
                    $yp1 = $y1 +($y2-$y1)*($jd-$axmin)/($axmax-$axmin);
                    $yp2 = $yp1o = $yp2o = $yp1;
                }
            }
            if ($grid && $jd > $axmin && $jd < $axmax) {
                if ($orient eq "horizontal") {
                    @coords = ($xp1, $gr1, $xp1, $gr2);
                } else {
                    @coords = ($gr1, $yp1, $gr2, $yp1);
                }
                $canv->create_line(@coords, -fill  => &get_rgb_code($grcolor),
                                            -width => $grwidth,
                                            -arrow => 'none',
                                            -tags  => $gridtags);
            }
            if ($pr_tics ne "none") {
                $canv->create_line($xp1, $yp1, $xp2, $yp2,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $tags);
            }
            if ($op_tics ne "none") {
                $canv->create_line($xp1o, $yp1o, $xp2o, $yp2o,
                                   -fill  => &get_rgb_code("black"),
                                   -width => 1,
                                   -arrow => 'none',
                                   -tags  => $op_tags);
            }
        }
    }
    if ($minor != 0 && ($pr_tics ne "none" || $op_tics ne "none")) {
        $nt = int(($axmax -$axmin)/$major +0.00001) +1;
        if ($orient eq "horizontal") {
            $add_minor = (abs($x2-$x1)/$nt > 30) ? 1 : 0;
        } else {
            $add_minor = (abs($y2-$y1)/$nt > 30) ? 1 : 0;
        }
        if ($add_minor) {
            if ($reverse) {
                for ($i=$axmax-$major/2.; $i>=$axmin; $i-=$major) {
                    if ($orient eq "horizontal") {
                        $xp4 = $x1 +($x2-$x1)*($axmax-$i)/($axmax-$axmin);
                        $xp5 = $xp4o = $xp5o = $xp4;
                    } else {
                        $yp4 = $y1 +($y2-$y1)*($axmax-$i)/($axmax-$axmin);
                        $yp5 = $yp4o = $yp5o = $yp4;
                    }
                    if ($pr_tics ne "none") {
                        $canv->create_line($xp4, $yp4, $xp5, $yp5,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $tags);
                    }
                    if ($op_tics ne "none") {
                        $canv->create_line($xp4o, $yp4o, $xp5o, $yp5o,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $op_tags);
                    }
                }
            } else {
                for ($i=$axmin+$major/2.; $i<=$axmax; $i+=$major) {
                    if ($orient eq "horizontal") {
                        $xp4 = $x1 +($x2-$x1)*($i-$axmin)/($axmax-$axmin);
                        $xp5 = $xp4o = $xp5o = $xp4;
                    } else {
                        $yp4 = $y1 +($y2-$y1)*($i-$axmin)/($axmax-$axmin);
                        $yp5 = $yp4o = $yp5o = $yp4;
                    }
                    if ($pr_tics ne "none") {
                        $canv->create_line($xp4, $yp4, $xp5, $yp5,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $tags);
                    }
                    if ($op_tics ne "none") {
                        $canv->create_line($xp4o, $yp4o, $xp5o, $yp5o,
                                           -fill  => &get_rgb_code("black"),
                                           -width => 1,
                                           -arrow => 'none',
                                           -tags  => $op_tags);
                    }
                }
            }
        }
    }
    for ($i=0; $i<=$#tick_jd2; $i++) {
        $jd    = $tick_jd2[$i];
        $label = $tick_labels2[$i];
        $d3    = ($pr_tics =~ /inside|none/) ? 6 : 0;
        if ($reverse) {
            if ($orient eq "horizontal") {
                $xp3 = $x1 +($x2-$x1)*($axmax-$jd)/($axmax-$axmin);
                $yp3 = ($side eq "bottom") ? $y1+9+$tsize+$xtra-$d3 : $y1-9-$tsize-$xtra+$d3;
            } else {
                $yp3 = $y1 +($y2-$y1)*($axmax-$jd)/($axmax-$axmin);
                $xp3 = ($side eq "left") ? $x1-12-$tsize+$d3 : $x1+12+$tsize-$d3;
            }
        } else {
            if ($orient eq "horizontal") {
                $xp3 = $x1 +($x2-$x1)*($jd-$axmin)/($axmax-$axmin);
                $yp3 = ($side eq "bottom") ? $y1+9+$tsize+$xtra-$d3 : $y1-9-$tsize-$xtra+$d3;
            } else {
                $yp3 = $y1 +($y2-$y1)*($jd-$axmin)/($axmax-$axmin);
                $xp3 = ($side eq "left") ? $x1-12-$tsize+$d3 : $x1+12+$tsize-$d3;
            }
        }
        $canv->create_text($xp3, $yp3,
                           -anchor => $anc,
                           -text   => $label,
                           -fill   => &get_rgb_code("black"),
                           -angle  => $ang,
                           -tags   => $tags,
                           -font   => [-family     => $family,
                                       -size       => $title_size,
                                       -weight     => $title_weight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
    }
    if ($title ne "" && $fmt ne "Mon-DD-YYYY") {
        $tags .= "Title";
        $d3    = ($pr_tics =~ /inside|none/) ? 6 : 0;
        if ($orient eq "horizontal") {
            $xp1 = ($x1+$x2)/2.;
            $ang = 0;
            $yp1 = ($side eq "bottom") ? $y1+9+$tsize+$xtra-$d3 : $y1-9-$tsize-$xtra+$d3;
            $anc = ($side eq "bottom") ? 'n' : 's';
        } else {
            $yp1 = ($y1+$y2)/2.;
            $anc = 's';
            $xp1 = ($side eq "left") ? $x1-12-$tsize+$d3 : $x1+12+$tsize-$d3;
            $ang = ($side eq "left") ? 90 : 270;
        }
        $canv->create_text($xp1, $yp1,
                           -anchor => $anc,
                           -text   => $title,
                           -fill   => &get_rgb_code("black"),
                           -angle  => $ang,
                           -tags   => $tags,
                           -font   => [-family     => $family,
                                       -size       => $title_size,
                                       -weight     => $title_weight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
    }
}


sub find_axis_limits {
    my ($axmin, $axmax) = @_;
    my (
        $i, $last_major, $last_ratio, $major, $power, $range, $ratio, $val,
        @mult,
       );

    @mult = (1, 2, 2.5, 3, 4, 5, 6, 7, 7.5, 8, 9, 10, 20, 25, 30, 40, 50);

    $axmin = 0. if ($axmin > 0 && $axmin < $axmax *0.2);
    $range = $axmax -$axmin;
    if ($range == 0.) {
        if ($axmin >= 0. && $axmin < 0.5) {
            $axmin = 0.0;
            $axmax = 1.0;
        } else {
            $axmin -= 0.5;
            $axmax += 0.5;
        }
        $major = 0.5;
        return ($axmin, $axmax, $major);
    }
    $power = &floor(&log10($range)) -1;
    $major = $mult[0] *(10**$power);
    $ratio = $range /$major;
    for ($i=1; $i<=$#mult; $i++) {
        $last_major = $major;
        $last_ratio = $ratio;
        $major = $mult[$i] *(10**$power);
        $ratio = $range /$major;
        if ($ratio < 5) {
            if (abs($ratio -5) < abs($last_ratio -5)) {
                last;
            } else {
                $major = $last_major;
                last;
            }
        }
    }
    $val = 0.;
    if ($axmin < 0) {
        while ($val > $axmin) {
            $val -= $major;
        }
    } else {
        while ($val +$major <= $axmin) {
            $val += $major;
        }
    }
    $axmin = $val;
    $val = 0.;
    if ($axmax < 0) {
        while ($val -$major >= $axmax) {
            $val -= $major;
        }
    } else {
        while ($val < $axmax) {
            $val += $major;
        }
    }
    $axmax = $val;

    return ($axmin, $axmax, $major);
}


sub make_color_key {
    my ($canv, %key_props) = @_;
    my (
        $ch, $clabel, $cmax, $cmin, $cw, $digits, $fmt, $fmt_w, $font,
        $i, $inc, $j, $range, $size1, $size2, $tag1, $tag2, $tags, $title,
        $weight1, $weight2, $xleg, $yleg, $ypos,

        @color, @scale,
       );

    $xleg    = $key_props{xleg};
    $yleg    = $key_props{yleg};
    $cw      = $key_props{width};
    $ch      = $key_props{height};
    $title   = $key_props{title};
    $font    = $key_props{font};
    $size1   = $key_props{size1};
    $size2   = $key_props{size2};
    $weight1 = $key_props{weight1};
    $weight2 = $key_props{weight2};
    $digits  = $key_props{digits};
    $tags    = $key_props{tags};
    @color   = @{ $key_props{colors} };
    @scale   = @{ $key_props{scale} };
    $range   = abs($scale[$#scale] -$scale[0]);

    if (defined($key_props{major}) && $key_props{major} ne "auto" && $key_props{major} ne "") {
        $inc = $key_props{major};
        if ($inc <= 0) {
            $inc = "auto";
        } elsif ($inc > $range) {
            $inc = $range;
        }
    } else {
        $inc = "auto";
    }

#   Format the scale numbers for display
    $fmt_w = length(int(&max(abs($scale[0]),abs($scale[$#scale]))));
    $fmt_w++ if ($scale[0] < 0 || $scale[$#scale] < 0);
    if ($digits > 0) {
        $fmt_w += $digits +1;
        $fmt = "%${fmt_w}.${digits}f";
    } else {
        $fmt = "%${fmt_w}d";
    }

#   Draw the color key
    for ($i=0; $i<=$#color; $i++) {
        $j = $#color -$i;
        $canv->create_rectangle($xleg, $yleg+$ch*$i, $xleg+$cw, $yleg+$ch*($i+1),
                         -outline => "",
                         -width   => 0,
                         -fill    => $color[$j],
                         -tags    => $tags);
    }

#   Add the numeric color labels
    if ($inc eq "auto") {
        for ($i=0; $i<=$#scale; $i++) {
            $scale[$i] = sprintf($fmt, $scale[$i]);
        }
        $inc = int($size1 /&max(1,$ch-2)) +1;
        for ($i=0; $i<=$#color+1; $i+=$inc) {
            $j = $#color +1 -$i;
            $canv->create_text($xleg+$cw+4, $yleg+$ch*$i,
                               -anchor  => 'w',
                               -text    => $scale[$j],
                               -fill    => &get_rgb_code("black"),
                               -angle   => 0,
                               -tags    => $tags,
                               -font    => [-family     => $font,
                                            -size       => $size1,
                                            -weight     => $weight1,
                                            -slant      => 'roman',
                                            -underline  => 0,
                                            -overstrike => 0,
                                           ]);
        }
    } else {
        $cmin = sprintf($fmt, $scale[0]);
        $cmax = sprintf($fmt, $scale[$#scale]);
        for ($i=$cmax; $i>=$cmin-0.000001; $i-=$inc) {
            $i = 0.0 if (abs($cmax-$cmin) > 0.00001 && abs($i) <= 0.000001);
            $clabel = sprintf($fmt, $i);
            $ypos = $yleg +$ch*($#color+1)*($cmax-$i)/$range;
            $canv->create_text($xleg+$cw+4, $ypos,
                               -anchor  => 'w',
                               -text    => $clabel,
                               -fill    => &get_rgb_code("black"),
                               -angle   => 0,
                               -tags    => $tags,
                               -font    => [-family     => $font,
                                            -size       => $size1,
                                            -weight     => $weight1,
                                            -slant      => 'roman',
                                            -underline  => 0,
                                            -overstrike => 0,
                                           ]);
        }
    }

#   Add the color key title
    if ($title ne "") {
        $tags .= "Title";
        $canv->create_text($xleg-5, $yleg+0.5*$ch*($#color+1),
                           -anchor  => 's',
                           -justify => 'center',
                           -text    => $title,
                           -fill    => &get_rgb_code("black"),
                           -angle   => 90,
                           -tags    => $tags,
                           -font    => [-family     => $font,
                                        -size       => $size2,
                                        -weight     => $weight2,
                                        -slant      => 'roman',
                                        -underline  => 0,
                                        -overstrike => 0,
                                       ]);
        ($tag1 = $tags) =~ s/.* //;
        $tag2 = substr($tag1,0,-5);
        $canv->addtag($tag2, withtag => $tag1);
    }
}


sub make_ts_legend {
    my ($canv, %legend_props) = @_;
    my (
        $box_tags, $edge, $edgec, $esize, $eweight, $fill, $fillc, $font,
        $leg_tag, $n, $ne, $tag, $tags, $title, $tsize, $tweight, $xpos,
        $ypos,
        @coords, @entries, @taglist,
       );

    $ne      = $legend_props{num};
    $xpos    = $legend_props{xpos};
    $ypos    = $legend_props{ypos};
    $title   = $legend_props{title};
    $font    = $legend_props{font};
    $esize   = $legend_props{esize};
    $tsize   = $legend_props{tsize};
    $eweight = $legend_props{eweight};
    $tweight = $legend_props{tweight};
    $edge    = $legend_props{edge};      # border: 0 = off, 1 = on
    $edgec   = $legend_props{edgec};     # border color
    $fill    = $legend_props{fill};      # fill: 0 = off, 1 = on
    $fillc   = $legend_props{fillc};     # fill color
    $tags    = $legend_props{tags};
    @entries = @{ $legend_props{entries} };

    $box_tags = $tags;
    @taglist = split(/ /, $box_tags);
    foreach $tag (@taglist) {
        if ($tag =~ /_legend$/) {
            $box_tags .= " " . $tag . "Box";
            $leg_tag   = $tag;
            last;
        }
    }

#   Create legend title
    if ($title ne "") {
        $canv->create_text($xpos, $ypos,
                           -anchor => 'w',
                           -text   => $title,
                           -fill   => &get_rgb_code("black"),
                           -angle  => 0,
                           -tags   => $tags,
                           -font   => [-family     => $font,
                                       -size       => $tsize,
                                       -weight     => $tweight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
        $ypos += $tsize *1.5;
    }

#   Create legend entries
    for ($n=0; $n<$ne; $n++) {
        $canv->create_line($xpos, $ypos, $xpos+20, $ypos,
                           -fill   => &get_rgb_code($entries[$n]{color}),
                           -width  => $entries[$n]{width},
                           -arrow  => 'none',
                           -tags   => $tags);
        $canv->create_text($xpos+25, $ypos,
                           -anchor => 'w',
                           -text   => $entries[$n]{text},
                           -fill   => &get_rgb_code("black"),
                           -angle  => 0,
                           -tags   => $tags,
                           -font   => [-family     => $font,
                                       -size       => $esize,
                                       -weight     => $eweight,
                                       -slant      => 'roman',
                                       -underline  => 0,
                                       -overstrike => 0,
                                      ]);
        $ypos += $esize *1.5;
    }

#   Create legend outline and fill, if requested
    if ((($edge && $edgec ne "") || ($fill && $fillc ne "")) && ($title ne "" || $ne > 0)) {
        @coords = Tkx::SplitList($canv->bbox($leg_tag));
        $coords[0] -= 5;
        $coords[1] -= 4;
        $coords[2] += 5;
        $coords[3] += 4;
        if ($edge && $edgec ne "" && $fill && $fillc ne "") {
            $canv->create_rectangle(@coords,
                           -outline => &get_rgb_code($edgec),
                           -width   => 1,
                           -fill    => &get_rgb_code($fillc),
                           -tags    => $box_tags);
        } elsif ($edge && $edgec ne "") {
            $canv->create_rectangle(@coords,
                           -outline => &get_rgb_code($edgec),
                           -width   => 1,
                           -fill    => "",
                           -tags    => $box_tags);
        } else {
            $canv->create_rectangle(@coords,
                           -outline => "",
                           -width   => 0,
                           -fill    => &get_rgb_code($fillc),
                           -tags    => $box_tags);
        }
    }
}


sub image_put_color {
    my ($image, $cshade, $xp1, $yp1, $xp2, $yp2) = @_;
    my ($cvert, $xp, $yp, @cdata);

#   Single rows or columns won't plot with 4-arg -to option.
    if ($xp1 != $xp2 && $yp1 != $yp2) {
        $image->put($cshade, -to => $xp1, $yp1, $xp2, $yp2);

    } elsif ($xp1 != $xp2) {
        @cdata    = ();
        $cdata[0] = $cshade;
        if ($xp2 > $xp1) {
            for ($xp=$xp1+1; $xp<=$xp2; $xp++) {
                $cdata[0] .= " " . $cshade;
            }
            $image->put([ @cdata ], -to => $xp1, $yp1);  # horizontal line
        } else {
            for ($xp=$xp2+1; $xp<=$xp1; $xp++) {
                $cdata[0] .= " " . $cshade;
            }
            $image->put([ @cdata ], -to => $xp2, $yp1);  # horizontal line
        }
    } elsif ($yp1 != $yp2) {
        $cvert = $cshade;
        if ($yp2 > $yp1) {
            for ($yp=$yp1+1; $yp<=$yp2; $yp++) {
                $cvert .= " " . $cshade;
            }
            $image->put($cvert, -to => $xp1, $yp1);      # vertical line
        } else {
            for ($yp=$yp2+1; $yp<=$yp1; $yp++) {
                $cvert .= " " . $cshade;
            }
            $image->put($cvert, -to => $xp1, $yp2);      # vertical line
        }
    } else {
        $image->put($cshade, -to => $xp1, $yp1);         # single point
    }
    return $image;
}


sub paint_slice_cell {
    my ($image, $cshade, $ih, $dy_full, $xflip, $xp1, $yp1, $xp2, $yp2) = @_;
    my ($cvert, $dy, $xp, $yp, $yp1r, $yp2r, $yp_start);

#   If slope is insignificant, just paint the rectangular cell
    if (&round_to_int($yp1+0.5*$dy_full) == &round_to_int($yp1-0.5*$dy_full) &&
        &round_to_int($yp2+0.5*$dy_full) == &round_to_int($yp2-0.5*$dy_full)) {
        $yp1r  = &max(0, &min($ih-1, &round_to_int($yp1)));
        $yp2r  = &max(0, &min($ih-1, &round_to_int($yp2)));
        $image = &image_put_color($image, $cshade, $xp1, $yp1r, $xp2, $yp2r);

#   Slope is noticeable.
#   Single columns won't plot with 4-arg -to option. Plot vertical lines for each x.
    } else {
        if ($xflip) {
            for ($xp=$xp2; $xp<=$xp1; $xp++) {
                $dy    = $dy_full*(($xp-$xp2)/($xp1-$xp2) -0.5);
                $yp1r  = &round_to_int($yp1+$dy);
                $yp2r  = &round_to_int($yp2+$dy);
                $cvert = "";
                for ($yp=$yp1r; $yp<=$yp2r; $yp++) {
                    next if ($yp < 0 || $yp > $ih-1);
                    if ($cvert eq "") {
                        $yp_start = $yp;
                        $cvert    = $cshade;
                    } else {
                        $cvert .= " " . $cshade;
                    }
                }
                if ($cvert ne "") {
                    $image->put($cvert, -to => $xp, $yp_start);
                }
            }
        } else {
            for ($xp=$xp1; $xp<=$xp2; $xp++) {
                $dy    = $dy_full*(($xp-$xp1)/($xp2-$xp1) -0.5);
                $yp1r  = &round_to_int($yp1-$dy);
                $yp2r  = &round_to_int($yp2-$dy);
                $cvert = "";
                for ($yp=$yp1r; $yp<=$yp2r; $yp++) {
                    next if ($yp < 0 || $yp > $ih-1);
                    if ($cvert eq "") {
                        $yp_start = $yp;
                        $cvert    = $cshade;
                    } else {
                        $cvert .= " " . $cshade;
                    }
                }
                if ($cvert ne "") {
                    $image->put($cvert, -to => $xp, $yp_start);
                }
            }
        }
    }
    return $image;
}


sub make_curve {
    my (@cpts) = @_;
    my ($bezier, $i, $j, $npts, @bpts);

    @bpts = ();
    $npts = ($#cpts +1)/2;
    for ($i=0; $i<$npts-1; $i+=3) {
        $j = 2*$i;
        $bezier = Math::Bezier->new($cpts[$j],   $cpts[$j+1], $cpts[$j+2], $cpts[$j+3],
                                    $cpts[$j+4], $cpts[$j+5], $cpts[$j+6], $cpts[$j+7]);
        if ($i > 0) {
            pop @bpts;
            pop @bpts;
        }
        push (@bpts, $bezier->curve(20));
    }
    return @bpts;
}


################################################################################
#
# Clipping subroutines
#
################################################################################

sub clip_profile {
    my ($x1, $x2, $y1, $y2, @coords) = @_;
    my ($i, $in_yrange, $last_pt, $npairs, $this_pt, $tmp, $xp1, $xp2, $yp1, $yp2,
        @cropped,
       );

    if ($x2 < $x1) {
        $tmp = $x1;
        $x1  = $x2;
        $x2  = $tmp;
    }
    if ($y2 < $y1) {
        $tmp = $y1;
        $y1  = $y2;
        $y2  = $tmp;
    }
    @cropped   = ();
    $in_yrange = 0;
    $last_pt   = "out";
    $npairs    = ($#coords+1)/2;

    for ($i=0; $i<$npairs; $i++) {
        $xp1 = $coords[2*$i];
        $yp1 = $coords[2*$i+1];
        $this_pt = "out";
        if ($yp1 >= $y1 && $yp1 <= $y2) {
            $in_yrange = 1;
            $this_pt   = "in" if ($xp1 >= $x1 && $xp1 <= $x2);
        }
        if ($i == 0) {
            if ($this_pt eq "in") {
                push (@cropped, $xp1, $yp1);
                $last_pt = "in";
            }
            next;
        }
        $xp2 = $coords[2*($i-1)];
        $yp2 = $coords[2*($i-1)+1];

      # Last point in and this point in.  No clipping.
        if ($last_pt eq "in" && $this_pt eq "in") {
            push (@cropped, $xp1, $yp1);
            next;

      # Last point out and this point out.
      # Check for a line crossing the clipping boundary.
        } elsif ($last_pt eq "out" && $this_pt eq "out") {
            next if (($xp1 < $x1 && $xp2 < $x1) || ($xp1 > $x2 && $xp2 > $x2) ||
                     ($yp1 < $y1 && $yp2 < $y1) || ($yp1 > $y2 && $yp2 > $y2));

          # Try to shift current point to clipping boundary
            if ($xp1 < $x1) {
                $yp1 = ($yp2-$yp1)*($x1-$xp1)/($xp2-$xp1)+$yp1;
                $xp1 = $x1;
            } elsif ($xp1 > $x2) {
                $yp1 = ($yp2-$yp1)*($x2-$xp1)/($xp2-$xp1)+$yp1;
                $xp1 = $x2;
            }
            if ($yp1 < $y1) {
                $xp1 = ($xp2-$xp1)*($y1-$yp1)/($yp2-$yp1)+$xp1;
                $yp1 = $y1;
            } elsif ($yp1 > $y2) {
                $xp1 = ($xp2-$xp1)*($y2-$yp1)/($yp2-$yp1)+$xp1;
                $yp1 = $y2;
            }
            next if ($xp1 < $x1 || $xp1 > $x2 || $yp1 < $y1 || $yp1 > $y2);

          # Try to shift last point to clipping boundary
            if ($xp2 < $x1) {
                $yp2 = ($yp1-$yp2)*($x1-$xp2)/($xp1-$xp2)+$yp2;
                $xp2 = $x1;
            } elsif ($xp2 > $x2) {
                $yp2 = ($yp1-$yp2)*($x2-$xp2)/($xp1-$xp2)+$yp2;
                $xp2 = $x2;
            }
            if ($yp2 < $y1) {
                $xp2 = ($xp1-$xp2)*($y1-$yp2)/($yp1-$yp2)+$xp2;
                $yp2 = $y1;
            } elsif ($yp2 > $y2) {
                $xp2 = ($xp1-$xp2)*($y2-$yp2)/($yp1-$yp2)+$xp2;
                $yp2 = $y2;
            }
            if ($xp2 >= $x1 && $xp2 <= $x2 && $yp2 >= $y1 && $yp2 <= $y2) {
                push (@cropped, $xp1, $yp1, $xp2, $yp2, -999, -999);
            }
            next;
        }

      # Last point in and this point out. Modify xp1, yp1 to clip boundary.
        if ($last_pt eq "in") {
            if ($xp1 < $x1) {
                $yp1 = ($yp2-$yp1)*($x1-$xp1)/($xp2-$xp1)+$yp1;
                $xp1 = $x1;
            } elsif ($xp1 > $x2) {
                $yp1 = ($yp2-$yp1)*($x2-$xp1)/($xp2-$xp1)+$yp1;
                $xp1 = $x2;
            }
            if ($yp1 < $y1) {
                $xp1 = ($xp2-$xp1)*($y1-$yp1)/($yp2-$yp1)+$xp1;
                $yp1 = $y1;
            } elsif ($yp1 > $y2) {
                $xp1 = ($xp2-$xp1)*($y2-$yp1)/($yp2-$yp1)+$xp1;
                $yp1 = $y2;
            }
            if ($xp1 >= $x1 && $xp1 <= $x2 && $yp1 >= $y1 && $yp1 <= $y2) {
                push (@cropped, $xp1, $yp1);
            }
            push (@cropped, -999, -999);
            $last_pt = "out";

      # Last point out and this point in. Modify xp2, yp2 to clip boundary.
        } else {
            if ($xp2 < $x1) {
                $yp2 = ($yp1-$yp2)*($x1-$xp2)/($xp1-$xp2)+$yp2;
                $xp2 = $x1;
            } elsif ($xp2 > $x2) {
                $yp2 = ($yp1-$yp2)*($x2-$xp2)/($xp1-$xp2)+$yp2;
                $xp2 = $x2;
            }
            if ($yp2 < $y1) {
                $xp2 = ($xp1-$xp2)*($y1-$yp2)/($yp1-$yp2)+$xp2;
                $yp2 = $y1;
            } elsif ($yp2 > $y2) {
                $xp2 = ($xp1-$xp2)*($y2-$yp2)/($yp1-$yp2)+$xp2;
                $yp2 = $y2;
            }
            if ($xp2 >= $x1 && $xp2 <= $x2 && $yp2 >= $y1 && $yp2 <= $y2) {
                push (@cropped, $xp2, $yp2);
            }
            push (@cropped, $xp1, $yp1);
            $last_pt = "in";
        }
    }
    return ($in_yrange, @cropped);
}


################################################################################
#
# Point manipulations
#
################################################################################

#
# Subroutine purge_points
#   Takes a set of (x, y) coordinate points and eliminates any intermediate
#   points that fall exactly along the line between neighboring points.
#   Useful for simplifying the raw data from a newly created "scribble" object.
#
sub purge_points {
    my (@coords) = @_;
    my (
        $b1, $b2, $i, $m1, $m2, $npts, $x0, $x1, $x2, $y0, $y1, $y2,
        @tmp,
       );

    $npts = int(($#coords+1)/2.);
    return @coords if ($npts < 3);

    @tmp = ();
    $x0  = $coords[0];
    $y0  = $coords[1];
    push (@tmp, $x0, $y0);

    $x1 = $coords[2];
    $y1 = $coords[3];
    for ($i=2; $i<$npts; $i++) {
        $x2 = $coords[2*$i];
        $y2 = $coords[2*$i+1];

#       Test whether (x1, y1) is on the line from (x0, y0) to (x2, y2).
#       If yes, then skip the point. If not, include it an move on.
#       First test: all three points on a horizontal or vertical line.
        if (($y0 == $y1 && $y0 == $y2) || ($x0 == $x1 && $x0 == $x2)) {
            $x1 = $x2;
            $y1 = $y2;
            next;

#       Two points on horizontal or vertical line, but third is not.
        } elsif ($x1 == $x0 || $x2 == $x0 || $y1 == $y0 || $y2 == $y0) {
            push (@tmp, $x1, $y1);
            $x0 = $x1;
            $y0 = $y1;
            $x1 = $x2;
            $y1 = $y2;
            next;
        }

#       Include point if slopes or intercepts are different.
        $m1 = ($y1 -$y0) /($x1 -$x0);
        $m2 = ($y2 -$y0) /($x2 -$x0);
        $b1 = $y1 -$m1*$x1;
        $b2 = $y2 -$m2*$x2;
        if ($m1 != $m2 || $b1 != $b2) {
            push (@tmp, $x1, $y1);
            $x0 = $x1;
            $y0 = $y1;
            $x1 = $x2;
            $y1 = $y2;

#       Same slope and intercept. Don't include.
        } else {
            $x1 = $x2;
            $y1 = $y2;
        }
    }
    push (@tmp, $x2, $y2);
    return @tmp;
}


#
# Subroutine rdp_resample
#   Implementation of the Ramer-Douglas-Peucker algorithm for recursive subsampling
#   of a set of points along a line or curve, returning a simpler representation
#   that is still within a user-provided tolerance.
#
sub rdp_resample {
    my ($tol, @pts) = @_;
    my ($d, $dmax, $i, $indx, $npts, $x, $x1, $x2, $y, $y1, $y2,
        @rpts, @rpts2,
       );

    $npts = ($#pts +1)/2;
    return @pts if ($npts <= 2);

    @rpts = ();   # resampled points
    $dmax = 0.;
    $indx = 0;
    $x1   = $pts[0];
    $y1   = $pts[1];
    $x2   = $pts[$#pts-1];
    $y2   = $pts[$#pts];

#   Compute the maximum perpendicular distance for each point between the endpoints
#   to the line between those endpoints.
    for ($i=1; $i<$npts; $i++) {
        $x = $pts[2*$i];
        $y = $pts[2*$i+1];
        $d = &perp_dist($x, $y, $x1, $y1, $x2, $y2);
        if ($d > $dmax) {
            $dmax = $d;
            $indx = 2*$i;
        }
    }

#   If the maximum distance is greater than the tolerance, split the line at the
#   point that gave the max distance, and recursively resample the two line segments
#   on either side.
    if ($dmax > $tol) {
        @rpts  = &rdp_resample($tol, @pts[0 .. ($indx+1)]);
        @rpts2 = &rdp_resample($tol, @pts[$indx .. $#pts]);
        pop @rpts;
        pop @rpts;
        push (@rpts, @rpts2);
    } else {
        @rpts = ($x1, $y1, $x2, $y2);
    }

#   Return the resampled point list
    return @rpts;
}


#
# Subroutine perp_dist
#   Compute the perpendicular distance between a point (x, y) and the line running
#   between two given points (x1, y1) and (x2, y2). Uses the law of cosines.
#
#   Modified for polygons to deal with (x1, y1) potentially same as (x2, y2).
#   In that case, just use distance from Pythagorean theorem.
#
sub perp_dist {
    my ($x, $y, $x1, $y1, $x2, $y2) = @_;
    my ($ang, $d, $d1, $d2, $pd);

    return 0.0 if (($x == $x1 && $y == $y1) || ($x == $x2 && $y == $y2));
    if ($x1 == $x2 && $y1 == $y2) {
        $pd  = sqrt(($x-$x1)*($x-$x1) +($y-$y1)*($y-$y1));
    } else {
        $d   = sqrt(($x2-$x1)*($x2-$x1) +($y2-$y1)*($y2-$y1));
        $d1  = sqrt(($x -$x1)*($x -$x1) +($y -$y1)*($y -$y1));
        $d2  = sqrt(($x -$x2)*($x -$x2) +($y -$y2)*($y -$y2));
        $ang = acos_real(($d*$d +$d1*$d1 -$d2*$d2)/(2.*$d*$d1));
        $pd  = abs($d1 *sin($ang));
    }
    return $pd;
}


################################################################################
#
# Trig calculation subroutines
#
################################################################################

sub make_shape_coords {
    my ($type, $xc, $yc, $hw, $hh, $ang) = @_;
    my ($ang2, $d, $i, $npts, $x, $y,
        @coords, @fr, @new_coords,
       );

    $hw = 0.001 if ($hw == 0.);
    $hh = 0.001 if ($hh == 0.);

#   Set up the initial shape without rotation or translation
    if ($type eq "rectangle") {
        @coords = (-$hw, -$hh, $hw, -$hh, $hw, $hh, -$hw, $hh);
        $npts   = 4;
    } elsif ($type eq "diamond") {
        @coords = (0, -$hh, $hw, 0, 0, $hh, -$hw, 0);
        $npts   = 4;
    } elsif ($type eq "ellipse") {
        @fr = ( 0.5,  1,  2,  3,  5,  8, 11, 15,   20, 25,
                 30, 35, 39, 42, 45, 47, 48, 49, 49.5, 50,
               50.5, 51, 52, 53, 55, 58, 61, 65,   70, 75,
                 80, 85, 89, 92, 95, 97, 98, 99, 99.5);
        @coords = (0, -$hh);
        for ($i=0; $i<=$#fr; $i++) {
            $y = -$hh +2 *$hh *$fr[$i] /100.;
            $x =  $hw *sqrt(1.- $y*$y/($hh*$hh));
            push (@coords, $x, $y);
        }
        push (@coords, 0, $hh);
        for ($i=0; $i<=$#fr; $i++) {
            $y =  $hh -2 *$hh *$fr[$i] /100.;
            $x = -$hw *sqrt(1.- $y*$y/($hh*$hh));
            push (@coords, $x, $y);
        }
        $npts = ($#coords +1)/2;
    } else {
        return ();
    }

#   Perform the rotation
    if ($ang != 0) {
        @new_coords = ();
        for ($i=0; $i<$npts; $i++) {
            $x = $coords[2*$i];
            $y = $coords[2*$i+1];
            $d = sqrt($x*$x +$y*$y);
            if ($x == 0) {
                if ($y == 0) {
                    $ang2 = 0;
                } else {
                    $ang2 = ($y > 0) ? 270 : 90;
                }
            } elsif ($y == 0) {
                $ang2 = ($x > 0) ? 0 : 180;
            } else {
                $ang2 = (180./pi)*atan2(-1*$y,$x);
            }
            $x =  $d *cos(($ang2 +$ang) *pi/180.);
            $y = -$d *sin(($ang2 +$ang) *pi/180.);
            push(@new_coords, $x, $y);
        }
        @coords = @new_coords;
    }

#   Perform the translation
    for ($i=0; $i<$npts; $i++) {
        $coords[2*$i]   += $xc;
        $coords[2*$i+1] += $yc;
    }
    return @coords;
}


sub find_rect_from_shape {
    my ($coords_ref, $ang) = @_;
    my ($ang2, $hh, $hw, $i, $npts, $x, $x1, $x2, $x3, $x4, $xc, $y, $y1,
        $y2, $y3, $y4, $yc,
        @coords, @xvals, @yvals,
       );

    @xvals  = @yvals = ();
    @coords = @{ $coords_ref };
    $npts   = ($#coords +1)/2.;
    for ($i=0; $i<$npts; $i++) {
        push (@xvals, $coords[2*$i]  );
        push (@yvals, $coords[2*$i+1]);
    }
    $xc = (&min(@xvals) + &max(@xvals))/2.;
    $yc = (&min(@yvals) + &max(@yvals))/2.;

#   Assume that height is from point 0 to point n/2
#   Assume that width is from point n/4 to point 3n/4
    $x1 = $xvals[0];
    $y1 = $yvals[0];
    $x2 = $xvals[$npts/2];
    $y2 = $yvals[$npts/2];
    $hh = sqrt(($x2-$x1)*($x2-$x1)+($y2-$y1)*($y2-$y1))/2.;
    $x3 = $xvals[$npts/4];
    $y3 = $yvals[$npts/4];
    $x4 = $xvals[$npts*3/4];
    $y4 = $yvals[$npts*3/4];
    $hw = sqrt(($x4-$x3)*($x4-$x3)+($y4-$y3)*($y4-$y3))/2.;

    if ($ang % 90 == 0) {
        if (abs($x2-$x1) < abs($y2-$y1)) {
            @coords = ($x1-$hw, $y1, $x1+$hw, $y1,
                       $x2+$hw, $y2, $x2-$hw, $y2);
        } else {
            @coords = ($x1, $y1+$hw, $x1, $y1-$hw,
                       $x2, $y2-$hw, $x2, $y2+$hw);
        }
    } else {
        if ($x1 == $x2) {
            if ($y1 == $y2) {
                $ang2 = 0;
            } else {
                $ang2 = ($y2 > $y1) ? 270 : 90;
            }
        } elsif ($y1 == $y2) {
            $ang2 = ($x2 > $x1) ? 0 : 180;
        } else {
            $ang2 = (180./pi)*atan2(($y1-$y2),($x2-$x1));
        }
        $ang2 += 360 if ($ang2 < 0);

        $x = $x1 -$hw *cos($ang *pi/180.);
        $y = $y1 +$hw *sin($ang *pi/180.);
        @coords = ($x, $y);
        $x = $x1 +$hw *cos($ang *pi/180.);
        $y = $y1 -$hw *sin($ang *pi/180.);
        push (@coords, $x, $y);
        $x = $x2 +$hw *cos($ang *pi/180.);
        $y = $y2 -$hw *sin($ang *pi/180.);
        push (@coords, $x, $y);
        $x = $x2 -$hw *cos($ang *pi/180.);
        $y = $y2 +$hw *sin($ang *pi/180.);
        push (@coords, $x, $y);
    }
    return @coords;
}


sub find_rect_from_poly {
    my ($coords_ref, $ang) = @_;
    my ($ang2, $d, $i, $npts, $x, $xmax, $xmin, $xo, $y, $ymax, $ymin, $yo,
        @coords, @new_coords, @xvals, @yvals,
       );

    @xvals  = @yvals = ();
    @coords = @{ $coords_ref };
    $npts   = ($#coords +1)/2.;
    for ($i=0; $i<$npts; $i++) {
        push (@xvals, $coords[2*$i]  );
        push (@yvals, $coords[2*$i+1]);
    }

#   Un-rotate the points, if needed
    if ($ang % 90 != 0) {
        $xo = $xvals[0];
        $yo = $yvals[0];
        for ($i=1; $i<$npts; $i++) {
            $x = $xvals[$i];
            $y = $yvals[$i];
            $d = sqrt(($x-$xo)*($x-$xo) +($y-$yo)*($y-$yo));
            if ($x == $xo) {
                if ($y == $yo) {
                    $ang2 = 0;
                } else {
                    $ang2 = ($y > $yo) ? 270 : 90;
                }
            } elsif ($y == $yo) {
                $ang2 = ($x > $xo) ? 0 : 180;
            } else {
                $ang2 = (180./pi)*atan2(($yo-$y),($x-$xo));
            }
            $ang2 += 360 if ($ang2 < 0);
            $xvals[$i] = $xo +$d *cos(($ang2 -$ang) *pi/180.);
            $yvals[$i] = $yo -$d *sin(($ang2 -$ang) *pi/180.);
        }
    }

#   Find the encompassing rectangle
    $xmin = &min(@xvals);
    $xmax = &max(@xvals);
    $ymin = &min(@yvals);
    $ymax = &max(@yvals);
    @coords = ($xmin, $ymin, $xmax, $ymin,
               $xmax, $ymax, $xmin, $ymax);

#   Re-rotate the rectangle, if needed
    if ($ang % 90 != 0) {
        @new_coords = ();
        for ($i=0; $i<4; $i++) {
            $x = $coords[2*$i];
            $y = $coords[2*$i+1];
            if ($x == $xo && $y == $yo) {
                push (@new_coords, $x, $y);
                next;
            }
            $d = sqrt(($x-$xo)*($x-$xo) +($y-$yo)*($y-$yo));
            if ($x == $xo) {
                $ang2 = ($y > $yo) ? 270 : 90;
            } elsif ($y == $yo) {
                $ang2 = ($x > $xo) ? 0 : 180;
            } else {
                $ang2 = (180./pi)*atan2(($yo-$y),($x-$xo));
            }
            $ang2 += 360 if ($ang2 < 0);
            $x = $xo +$d *cos(($ang2 +$ang) *pi/180.);
            $y = $yo -$d *sin(($ang2 +$ang) *pi/180.);
            push (@new_coords, $x, $y);
        }
        @coords = @new_coords;
    }
    return @coords;
}


sub resize_shape {
    my ($coords_ref, $ang_orig, $xa, $ya, $dx, $dy, $ang) = @_;
    my ($ang2, $d, $dx_orig, $dy_orig, $i, $npts, $x, $xmult, $y, $ymult,
        @coords, @xvals, @yvals,
       );

    @xvals  = @yvals = ();
    @coords = @{ $coords_ref };
    $npts   = ($#coords +1)/2.;
    for ($i=0; $i<$npts; $i++) {
        push (@xvals, $coords[2*$i]  );
        push (@yvals, $coords[2*$i+1]);
    }

#   Un-rotate the points, if needed
    if ($ang_orig != 0) {
        for ($i=0; $i<$npts; $i++) {
            $x = $xvals[$i];
            $y = $yvals[$i];
            next if ($x == $xa && $y == $ya);
            $d = sqrt(($x-$xa)*($x-$xa) +($y-$ya)*($y-$ya));
            if ($x == $xa) {
                $ang2 = ($y > $ya) ? 270 : 90;
            } elsif ($y == $ya) {
                $ang2 = ($x > $xa) ? 0 : 180;
            } else {
                $ang2 = (180./pi)*atan2(($ya-$y),($x-$xa));
            }
            $ang2 += 360 if ($ang2 < 0);
            $xvals[$i] = $xa +$d *cos(($ang2 -$ang_orig) *pi/180.);
            $yvals[$i] = $ya -$d *sin(($ang2 -$ang_orig) *pi/180.);
        }
    }

#   Find the multiplier for size changes
    $dx_orig = &max(@xvals) - &min(@xvals);
    $dy_orig = &max(@yvals) - &min(@yvals);
    $xmult   = ($dx_orig > 0) ? $dx/$dx_orig : 0;
    $ymult   = ($dy_orig > 0) ? $dy/$dy_orig : 0;

#   Find resized points in non-rotated space
    for ($i=0; $i<$npts; $i++) {
        $x = $xvals[$i];
        $y = $yvals[$i];
        next if ($x == $xa && $y == $ya);
        $d = sqrt(($x-$xa)*($x-$xa) +($y-$ya)*($y-$ya));
        if ($x == $xa) {
            $ang2 = ($y > $ya) ? 270 : 90;
        } elsif ($y == $ya) {
            $ang2 = ($x > $xa) ? 0 : 180;
        } else {
            $ang2 = (180./pi)*atan2(($ya-$y),($x-$xa));
        }
        $ang2 += 360 if ($ang2 < 0);
        $xvals[$i] = $xa +$xmult *$d *cos($ang2 *pi/180.);
        $yvals[$i] = $ya -$ymult *$d *sin($ang2 *pi/180.);
    }

#   Re-rotate the shape, if needed
    if ($ang != 0) {
        for ($i=0; $i<$npts; $i++) {
            $x = $xvals[$i];
            $y = $yvals[$i];
            next if ($x == $xa && $y == $ya);
            $d = sqrt(($x-$xa)*($x-$xa) +($y-$ya)*($y-$ya));
            if ($x == $xa) {
                $ang2 = ($y > $ya) ? 270 : 90;
            } elsif ($y == $ya) {
                $ang2 = ($x > $xa) ? 0 : 180;
            } else {
                $ang2 = (180./pi)*atan2(($ya-$y),($x-$xa));
            }
            $ang2 += 360 if ($ang2 < 0);
            $xvals[$i] = $xa +$d *cos(($ang2 +$ang) *pi/180.);
            $yvals[$i] = $ya -$d *sin(($ang2 +$ang) *pi/180.);
        }
    }
    @coords = ();
    for ($i=0; $i<$npts; $i++) {
        push (@coords, $xvals[$i], $yvals[$i]);
    }
    return @coords;
}


################################################################################
#
# Multidimensional minimization subroutines
#
################################################################################

{
    my (@coords);    # Share an array of coordinates among several subroutines

  #
  # Subroutine to begin process of finding the center of the smallest circle
  # that encompasses a set of points.
  #
    sub smallest_circle {
        (@coords) = @_;
        my ($best_ref, $i, $iter, $maxx, $maxy, $minx, $miny, $npts, $r, $x, $y,
            @best, @p, @v,
           );

        $minx = $maxx = $coords[0];
        $miny = $maxy = $coords[1];
        $npts = ($#coords +1)/2;
        for ($i=1; $i<$npts; $i++) {
            $minx = $coords[2*$i]   if ($minx > $coords[2*$i]  );
            $maxx = $coords[2*$i]   if ($maxx < $coords[2*$i]  );
            $miny = $coords[2*$i+1] if ($miny > $coords[2*$i+1]);
            $maxy = $coords[2*$i+1] if ($maxy < $coords[2*$i+1]);
        }

      # Initial guess of center of circle, and two nearby points
        $p[0][0] = $x = ($minx +$maxx)/2.;
        $p[0][1] = $y = ($miny +$maxy)/2.;
        $v[0]    = &max_dist( @{ $p[0] } );

        $p[1][0] = $x-4;
        $p[1][1] = $y-4;
        $v[1]    = &max_dist( @{ $p[1] } );

        $p[2][0] = $x+4;
        $p[2][1] = $y-4;
        $v[2]    = &max_dist( @{ $p[2] } );

        ($best_ref, $r, $iter) = &amoeba(\@p, \@v, 2, 0.00001, "max_dist");
        @best = @{ $best_ref };
        return ($best[0], $best[1], $r);
    }


  #
  # Subroutine to find greatest distance (radius) from a point.
  # This is the function being minimized by the smallest_circle subroutine.
  #
    sub max_dist {
        my (@pt) = @_;
        my ($i, $maxr, $n, $r, $x, $xo, $y, $yo);

        $maxr = 0;
        $n    = ($#coords +1)/2;
        $xo   = $pt[0];
        $yo   = $pt[1];

        for ($i=0; $i<$n; $i++) {
            $x = $coords[2*$i];
            $y = $coords[2*$i+1];
            $r = sqrt(($x-$xo)*($x-$xo)+($y-$yo)*($y-$yo));
            $maxr = $r if ($maxr < $r);
        }
        return $maxr;
    }
}


{
  # Share some variables among the fit_curve, curve_error, and curve_error2 subroutines
    my ($cform, $cindx, @coords, @cp_indx, @cpts, @ptypes, @tvals);

  #
  # Subroutine fit_curve
  #   This routine begins the process of fitting one or more cubic Bezier
  #   curves to a set of points along a line, given those points and a
  #   subset of those points to use as Bezier curve endpoints.
  #
  # Fitting all of the points to a set of interconnected Bezier curves
  # all at once does not result in a good optimization, as that process
  # has too many fitting parameters to always work well.  It is best to
  # break the problem apart and fit each Bezier curve individually.
  #
  # The process is done in two stages, depending on user input.
  #
  # (1) In part 1, each of the Bezier curve endpoints is assumed to be a
  #     "corner" point, such that the tangent is not preserved at any
  #     Bezier endpoint that has a curve on both sides.  The coordinates
  #     of the intermediate Bezier points for each curve are allowed to
  #     wander during the minimization. Four parameters are optimized for
  #     each curve, corresponding to the x and y coordinates of those two
  #     intermediate points.
  #
  # (2) If the user wishes to preserve the curve slope at each Bezier
  #     endpoint, then part 2 is used in an attempt to transform some of the
  #     "corner" points into "straight" points where the initial angle is
  #     set as the average of the part 1 result, and then those angles and
  #     the distances to the two intermediate control points is allowed
  #     to vary.  If the angles from part 1 are too different (more than
  #     a user-defined angle [default 50 degrees]), then the point type
  #     of "corner" is retained. For "straight" points, the minimization
  #     includes the error from the next adjacent Bezier curve, but the
  #     handle distance on that side is not varied. Four parameters are
  #     optimized for each Bezier curve, corresponding to the angles and
  #     distances from each endpoint to the two intermediate control points.
  #     When part 2 is run, even the curves between corner points will be
  #     re-fit, using angles and distances.
  #
  # The minimization for part 1 is run in 4-dimensional space (2 x,y
  # locations) with 5 sets of initial values.  For part 2, the minimization
  # also is run in 4 dimensions (2 angles and 2 distances) with 5 sets of
  # initial values.  The distances in part 2 are constrained to be positive.
  #
  # The curv_form argument indicates the curve form: "open" or "closed".
  #
    sub fit_curve {
        my ($coords_ref, $rpts_ref, $part2, $ang_crit, $curv_form) = @_;
        my (
            $adif, $ang, $ang1, $ang2, $ang3, $ang4, $best_ref, $d,
            $dsum, $err, $i, $iter, $j, $n, $n1, $n2, $npts, $pts_ahead,
            $pts_behind, $sum_err, $x, $x0, $x1, $x2, $x3, $xo, $y, $y0,
            $y1, $y2, $y3, $yo,

            @best, @p, @rpts, @v,
           );

        $part2    =  0 if (! defined($part2) || $part2 != 1);
        $ang_crit = 50 if (! defined($ang_crit) || $ang_crit eq "" || $ang_crit < 0);
        $cform    = (! defined($curv_form) || $curv_form ne "closed") ? "open" : "closed";

      # Set up shared coordinates and indices. @rpts is a subset of @coords.
        @coords  = @{ $coords_ref };   # (x, y) coordinates for each point on the line
        @rpts    = @{ $rpts_ref };     # (x, y) coordinates for Bezier curve endpoints
        @cp_indx = ();
        if ($cform eq "closed" && ($coords[0] != $coords[$#coords-1] || $rpts[0] != $rpts[$#rpts-1] ||
                                   $coords[1] != $coords[$#coords]   || $rpts[1] != $rpts[$#rpts])) {
            push (@coords, $coords[0], $coords[1]);
            push (@rpts,   $rpts[0],   $rpts[1]);
        }
        $n = 0;
        for ($i=0; $i<$#coords; $i+=2) {
            if ($coords[$i] == $rpts[$n] && $coords[$i+1] == $rpts[$n+1]) {
                push (@cp_indx, $i);
                $n += 2;
            }
        }

      # Return early if no data are available to fit a curve
        if ($#rpts == $#coords) {
            @cpts = ($rpts[0], $rpts[1]);
            for ($n=0; $n<$#cp_indx; $n++) {
                $x0  = $coords[$cp_indx[$n]];
                $y0  = $coords[$cp_indx[$n] +1];
                $x3  = $coords[$cp_indx[$n+1]];
                $y3  = $coords[$cp_indx[$n+1] +1];
                $ang = atan2(($y0-$y3),($x3-$x0));
                $d   = 0.3 *sqrt(($x0-$x3)*($x0-$x3) +($y0-$y3)*($y0-$y3));
                $x1  = $x0 +$d *cos($ang);
                $y1  = $y0 -$d *sin($ang);
                $x2  = $x3 -$d *cos($ang);
                $y2  = $y3 +$d *sin($ang);
                push (@cpts, $x1, $y1, $x2, $y2, $x3, $y3);
            }
            @ptypes = ("corner") x @cp_indx;
            return (\@cpts, \@ptypes);
        }

      # The distance along each Bezier curve ranges from 0 to 1, and any
      # measured values between Bezier curve endpoints will be compared
      # using that distance scale.  Need to compute t values for every
      # point that is not a control point.
        $npts  = ($#coords +1)/2;
        @tvals = (0) x $npts;
        for ($n=0; $n<$#cp_indx; $n++) {
            $dsum = 0.;
            $xo = $coords[$cp_indx[$n]];
            $yo = $coords[$cp_indx[$n] +1];
            for ($i=$cp_indx[$n]+2; $i<=$cp_indx[$n+1]; $i+=2) {
                $x  = $coords[$i];
                $y  = $coords[$i+1];
                $d  = sqrt(($x-$xo)*($x-$xo) +($y-$yo)*($y-$yo));
                $xo = $x;
                $yo = $y;
                $tvals[$i/2] = $d +$dsum if ($i < $cp_indx[$n+1]);
                $dsum += $d;
            }
            for ($i=$cp_indx[$n]+2; $i<$cp_indx[$n+1]; $i+=2) {
                $tvals[$i/2] /= $dsum if ($dsum > 0.);
            }
        }

      # Part 1 -- All Bezier endpoints treated as "corner" points
        $sum_err = 0.;
        @cpts    = ($rpts[0], $rpts[1]);
        for ($n=0; $n<$#cp_indx; $n++) {    # one Bezier curve at a time
            @p = @v = ();
            $x1  = $coords[$cp_indx[$n]];
            $y1  = $coords[$cp_indx[$n] +1];
            $x2  = $coords[$cp_indx[$n+1]];
            $y2  = $coords[$cp_indx[$n+1] +1];

          # Default angle is towards next control point
            $ang1 = atan2(($y1-$y2),($x2-$x1));
            $ang2 = $ang1;
            $d    = 0.3 *sqrt(($x2-$x1)*($x2-$x1) +($y2-$y1)*($y2-$y1));

          # If nearby points available, compute an appropriate alternate angle.
          # Use the nearest two points if both have a t value within 0.2.
          # But, if the slopes from those two points are quite different (>90 deg), revert.
          # Use the nearest point if that's the only one with a t value within 0.2.
            $npts = ($cp_indx[$n+1] -$cp_indx[$n]) /2 -1;
            if ($npts > 0) {
                $n1 = $cp_indx[$n]/2 +1;
                $n2 = $n1 +1;
                if ($npts >= 2 && $tvals[$n2] <= 0.2) {
                    $x    = $coords[2*$n1];
                    $y    = $coords[2*$n1 +1];
                    $ang3 = atan2(($y1-$y),($x-$x1));
                    $x    = $coords[2*$n2];
                    $y    = $coords[2*$n2 +1];
                    $ang4 = atan2(($y1-$y),($x-$x1));
                    $adif = (abs($ang3-$ang4) > pi) ? abs($ang3-$ang4) -2*pi : abs($ang3-$ang4);
                    $adif += 2*pi if ($adif <= -1*pi);
                    if (abs($adif) < pi/2.) {
                        $ang1 = (abs($ang3-$ang4) > pi) ? ($ang3+$ang4)/2. -pi: ($ang3+$ang4)/2.;
                        $ang1 += 2*pi if ($ang1 <= -1*pi);
                    }
                } elsif ($npts >= 1 && $tvals[$n1] <= 0.2) {
                    $x    = $coords[2*$n1];
                    $y    = $coords[2*$n1 +1];
                    $ang1 = atan2(($y1-$y),($x-$x1));
                }
                $n1 = $cp_indx[$n+1]/2 -1;
                $n2 = $n1 -1;
                if ($npts >= 2 && $tvals[$n2] >= 0.8) {
                    $x    = $coords[2*$n1];
                    $y    = $coords[2*$n1 +1];
                    $ang3 = atan2(($y-$y2),($x2-$x));
                    $x    = $coords[2*$n2];
                    $y    = $coords[2*$n2 +1];
                    $ang4 = atan2(($y-$y2),($x2-$x));
                    $adif = (abs($ang3-$ang4) > pi) ? abs($ang3-$ang4) -2*pi : abs($ang3-$ang4);
                    $adif += 2*pi if ($adif <= -1*pi);
                    if (abs($adif) < pi/2.) {
                        $ang2 = (abs($ang3-$ang4) > pi) ? ($ang3+$ang4)/2. -pi: ($ang3+$ang4)/2.;
                        $ang2 += 2*pi if ($ang2 <= -1*pi);
                    }
                } elsif ($npts >= 1 && $tvals[$n1] >= 0.8) {
                    $x    = $coords[2*$n1];
                    $y    = $coords[2*$n1 +1];
                    $ang2 = atan2(($y-$y2),($x2-$x));
                }
            }

          # Initial coordinates of the two interior control points
            $p[0][0] = $x1 +$d *cos($ang1);
            $p[0][1] = $y1 -$d *sin($ang1);
            $p[0][2] = $x2 -$d *cos($ang2);
            $p[0][3] = $y2 +$d *sin($ang2);

            push (@cpts, $p[0][0], $p[0][1], $p[0][2], $p[0][3], $x2, $y2);
            next if ($cp_indx[$n+1] == $cp_indx[$n] +2);

          # Initialize alternate coordinates for minimization
            $p[1][0] = $p[0][0] -10;
            $p[1][1] = $p[0][1] -10;
            $p[1][2] = $p[0][2] -10;
            $p[1][3] = $p[0][3] -10;

            $p[2][0] = $p[0][0] +10;
            $p[2][1] = $p[0][1] -10;
            $p[2][2] = $p[0][2] +10;
            $p[2][3] = $p[0][3] -10;

            $p[3][0] = $p[0][0] -10;
            $p[3][1] = $p[0][1] +10;
            $p[3][2] = $p[0][2] -10;
            $p[3][3] = $p[0][3] +10;

            $p[4][0] = $p[0][0] +10;
            $p[4][1] = $p[0][1] +10;
            $p[4][2] = $p[0][2] +10;
            $p[4][3] = $p[0][3] +10;

            $cindx = $n;                  # starting index needed for curve_error
            for ($i=0; $i<=4; $i++) {
                $v[$i] = &curve_error( @{ $p[$i] } );
            }

          # Call the multidimensional minimization subroutine
          # @p are the parameters, @v are the initial values, 
            ($best_ref, $err, $iter) = &amoeba(\@p, \@v, 4, 0.00001, "curve_error");
            @best = @{ $best_ref };
            $sum_err += $err;

          # Save the optimized intermediate Bezier control points
            splice (@cpts, -6, 4, @best);
        }
        @ptypes = ("corner") x @cp_indx;
        return (\@cpts, \@ptypes) if (! $part2);

      # Part 2 -- Try to convert some Bezier endpoints from "corner" to "straight."
      #           Also, re-run the curve fit using angles and distances.
      #
      # The first task is to evaluate the results from part 1 to see which
      # endpoints may be converted. If the part-1 results show corner angles
      # that are within a user-defined critical angle (default 50 degrees),
      # then the point type will be switched to "straight."
      #
      # For a closed curve, must account for first and last points being the same.
        for ($n=0; $n<$#ptypes; $n++) {
            next if ($n == 0 && $cform eq "open");
            $xo = $cpts[6*$n];           # control point of interest
            $yo = $cpts[6*$n +1];
            $x2 = $cpts[6*$n +2];        # handle after ctrl pt
            $y2 = $cpts[6*$n +3];
            if ($n == 0) {
                $x1 = $cpts[$#cpts -3];  # handle before ctrl pt; n=0 and closed curve
                $y1 = $cpts[$#cpts -2];
            } else {
                $x1 = $cpts[6*$n -2];    # handle before ctrl pt
                $y1 = $cpts[6*$n -1];
            }
            $ang1 = atan2(($y1-$yo),($xo-$x1));
            $ang2 = atan2(($yo-$y2),($x2-$xo));
            $adif = (abs($ang1-$ang2) > pi) ? abs($ang1-$ang2) -2*pi : abs($ang1-$ang2);
            $adif += 2*pi if ($adif <= -1*pi);

          # If angles are similar, take the average and adjust adjacent ctrl pt locations
            if (abs($adif) *180./pi <= $ang_crit) {
                $ptypes[$n] = "straight";
                $ang  = (abs($ang1-$ang2) > pi) ? ($ang1+$ang2)/2. -pi: ($ang1+$ang2)/2.;
                $ang += 2*pi if ($ang <= -1*pi);
                $d    = sqrt(($xo-$x2)*($xo-$x2) +($yo-$y2)*($yo-$y2));
                $cpts[6*$n +2] = $xo +$d *cos($ang);
                $cpts[6*$n +3] = $yo -$d *sin($ang);
                $d    = sqrt(($xo-$x1)*($xo-$x1) +($yo-$y1)*($yo-$y1));
                if ($n == 0) {
                    $cpts[$#cpts -3]  = $xo -$d *cos($ang);
                    $cpts[$#cpts -2]  = $yo +$d *sin($ang);
                    $ptypes[$#ptypes] = "straight";
                } else {
                    $cpts[6*$n -2] = $xo -$d *cos($ang);
                    $cpts[6*$n -1] = $yo +$d *sin($ang);
                }
            }
        }

      # Parameters for optimization are the angle and distance for the Bezier curve handles
        $sum_err = 0.;
        for ($n=0; $n<$#cp_indx; $n++) {

          # Skip this curve if no comparison points are available
            if ($cp_indx[$n+1] == $cp_indx[$n] +2) {
                next if ($ptypes[$n] eq "corner" && $ptypes[$n+1] eq "corner");
                $pts_ahead = $pts_behind = 0;
                if ($n+1 < $#cp_indx) {
                    $pts_ahead = ($cp_indx[$n+2] -$cp_indx[$n+1] -2) /2;
                } elsif ($cform eq "closed") {
                    $pts_ahead = ($cp_indx[1] -$cp_indx[0] -2) /2;
                }
                if ($n > 0) {
                    $pts_behind = ($cp_indx[$n] -$cp_indx[$n-1] -2) /2;
                } elsif ($cform eq "closed") {
                    $pts_behind = ($cp_indx[$#cp_indx] -$cp_indx[$#cp_indx-1] -2) /2;
                }
                next if (($ptypes[$n]   eq "corner" && $pts_ahead  == 0) ||
                         ($ptypes[$n+1] eq "corner" && $pts_behind == 0) ||
                         ($pts_ahead == 0 && $pts_behind == 0));
            }

          # Get point coordinates and angles
            @p = @v = ();
            $x0   = $cpts[6*$n];
            $y0   = $cpts[6*$n +1];
            $x1   = $cpts[6*$n +2];
            $y1   = $cpts[6*$n +3];
            $x2   = $cpts[6*$n +4];
            $y2   = $cpts[6*$n +5];
            $x3   = $cpts[6*$n +6];
            $y3   = $cpts[6*$n +7];
            $ang1 = atan2(($y0-$y1),($x1-$x0)) *180./pi;
            $ang2 = atan2(($y2-$y3),($x3-$x2)) *180./pi;

          # Initial angles and distances for the two interior handles
            $p[0][0] = $ang1;
            $p[0][1] = sqrt(($x0-$x1)*($x0-$x1) +($y0-$y1)*($y0-$y1));
            $p[0][2] = $ang2;
            $p[0][3] = sqrt(($x2-$x3)*($x2-$x3) +($y2-$y3)*($y2-$y3));

          # Initialize other angles and distances
            $p[1][0] = $p[0][0] -5;
            $p[1][1] = $p[0][1] *0.85;
            $p[1][2] = $p[0][2] -5;
            $p[1][3] = $p[0][3] *0.85;

            $p[2][0] = $p[0][0] +5;
            $p[2][1] = $p[0][1] *0.85;
            $p[2][2] = $p[0][2] +5;
            $p[2][3] = $p[0][3] *0.85;

            $p[3][0] = $p[0][0] -5;
            $p[3][1] = $p[0][1] *1.18;
            $p[3][2] = $p[0][2] -5;
            $p[3][3] = $p[0][3] *1.18;

            $p[4][0] = $p[0][0] +5;
            $p[4][1] = $p[0][1] *1.18;
            $p[4][2] = $p[0][2] +5;
            $p[4][3] = $p[0][3] *1.18;

            $cindx = $n;                  # starting index needed for curve_error
            for ($j=0; $j<=4; $j++) {
                $v[$j] = &curve_error2( @{ $p[$j] } );
            }

          # Call the multidimensional minimization subroutine
          # @p are the parameters, @v are the initial values, 
            ($best_ref, $err, $iter) = &amoeba(\@p, \@v, 4, 0.00001, "curve_error2");
            @best = @{ $best_ref };
            $sum_err += $err;

          # Save the optimized intermediate Bezier control points
            $ang1 = $best[0] *pi/180.;
            $ang2 = $best[2] *pi/180.;
            $cpts[6*$n +2] = $cpts[6*$n]    +&max(1, $best[1]) *cos($ang1);
            $cpts[6*$n +3] = $cpts[6*$n +1] -&max(1, $best[1]) *sin($ang1);
            $cpts[6*$n +4] = $cpts[6*$n +6] -&max(1, $best[3]) *cos($ang2);
            $cpts[6*$n +5] = $cpts[6*$n +7] +&max(1, $best[3]) *sin($ang2);

          # Save control points from adjacent curves if they were modified
            if ($ptypes[$n] ne "corner" && ($n > 0 || $cform eq "closed")) {
                $x0 = $cpts[6*$n];
                $y0 = $cpts[6*$n +1];
                $n1 = ($n == 0 && $cform eq "closed") ? $#cpts -3 : 6*$n -2;
                $x1 = $cpts[$n1];
                $y1 = $cpts[$n1 +1];
                $d  = sqrt(($x0-$x1)*($x0-$x1) +($y0-$y1)*($y0-$y1));
                $cpts[$n1]    = $x0 -$d *cos($ang1);
                $cpts[$n1 +1] = $y0 +$d *sin($ang1);
            }
            if ($ptypes[$n+1] ne "corner" && ($n+1 < $#ptypes || $cform eq "closed")) {
                $x0 = $cpts[6*($n+1)];
                $y0 = $cpts[6*($n+1) +1];
                $n1 = ($n+1 == $#ptypes && $cform eq "closed") ? 2 : 6*($n+1) +2;
                $x1 = $cpts[$n1];
                $y1 = $cpts[$n1 +1];
                $d  = sqrt(($x0-$x1)*($x0-$x1) +($y0-$y1)*($y0-$y1));
                $cpts[$n1]    = $x0 +$d *cos($ang2);
                $cpts[$n1 +1] = $y0 -$d *sin($ang2);
            }
        }
        return (\@cpts, \@ptypes);
    }

  #
  # Subroutine curve_error
  #   This function computes the sum of the squared distance errors for
  #   the target Bezier curve relative to any points between the Bezier
  #   endpoints.  The target curve is identified based on the cindx variable.
  #   The four minimized parameters are the x,y coordinates of the two
  #   intermediate control points on the cubic Bezier curve.
  #
    sub curve_error {
        my (@parms) = @_;
        my ($bezier, $i, $n, $sum_err, $t, $x0, $x1, $x2, $x3, $xb, $xp,
            $y0, $y1, $y2, $y3, $yb, $yp,
           );

      # Fitting one Bezier curve at a time.
      # The index of the first x coordinate is saved in $cindx.
        $n = $cindx;
        return 0. if ($cp_indx[$n+1] == $cp_indx[$n] +2);

      # Set the control points for the Bezier curve.
        $x0 = $coords[$cp_indx[$n]];      # one Bezier endpoint
        $y0 = $coords[$cp_indx[$n] +1];
        $x3 = $coords[$cp_indx[$n+1]];    # the other Bezier endpoint
        $y3 = $coords[$cp_indx[$n+1] +1];
        $x1 = $parms[0];
        $y1 = $parms[1];
        $x2 = $parms[2];
        $y2 = $parms[3];

        $bezier = Math::Bezier->new($x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3);

      # Compute the sum of the squared distance errors
      # for each point that is not a control point
        $sum_err = 0.;
        for ($i=$cp_indx[$n]+2; $i<$cp_indx[$n+1]; $i+=2) {
            $xp = $coords[$i];
            $yp = $coords[$i+1];
            $t  = $tvals[$i/2];
            ($xb, $yb) = $bezier->point($t);
            $sum_err  += ($xp-$xb)*($xp-$xb) +($yp-$yb)*($yp-$yb);
        }
        return $sum_err;
    }

  #
  # Subroutine curve_error2
  #   This function computes the sum of the squared distance errors for the
  #   target Bezier curve and any adjacent Bezier curves, if necessary,
  #   relative to any points between the Bezier endpoints.  The target
  #   curve is identified based on the cindx variable.  The four minimized
  #   parameters are the angles and distances from the Bezier endpoints
  #   to the coordinates of the two intermediate control points on the
  #   cubic Bezier curve. In this minimization, the optimized angle is in
  #   degrees so that it might be of similar magnitude to the distances.
  #
    sub curve_error2 {
        my (@parms) = @_;
        my (

            $ang0, $ang3, $bezier, $d, $i, $n, $n1, $pts_ahead, $pts_behind,
            $sum_err, $t, $x0, $x1, $x2, $x3, $xb, $xp, $y0, $y1, $y2,
            $y3, $yb, $yp,
           );

      # Fitting one Bezier curve at a time.
      # The index of the first x coordinate is saved in $cindx.
      # Return early if no comparison points are available.
      # Tests in the fit_curve routine should make this test unnecessary.
        $n = $cindx;
        if ($cp_indx[$n+1] == $cp_indx[$n] +2) {
            return 0. if ($ptypes[$n] eq "corner" && $ptypes[$n+1] eq "corner");
            $pts_ahead = $pts_behind = 0;
            if ($n+1 < $#cp_indx) {
                $pts_ahead = ($cp_indx[$n+2] -$cp_indx[$n+1] -2) /2;
            } elsif ($cform eq "closed") {
                $pts_ahead = ($cp_indx[1] -$cp_indx[0] -2) /2;
            }
            if ($n > 0) {
                $pts_behind = ($cp_indx[$n] -$cp_indx[$n-1] -2) /2;
            } elsif ($cform eq "closed") {
                $pts_behind = ($cp_indx[$#cp_indx] -$cp_indx[$#cp_indx-1] -2) /2;
            }
            return 0. if (($ptypes[$n]   eq "corner" && $pts_ahead  == 0) ||
                          ($ptypes[$n+1] eq "corner" && $pts_behind == 0) ||
                          ($pts_ahead == 0 && $pts_behind == 0));
        }

      # Set the control points for the indexed Bezier curve.
        $x0   = $cpts[6*$n];        # one Bezier endpoint
        $y0   = $cpts[6*$n +1];
        $x3   = $cpts[6*($n+1)];    # the other Bezier endpoint
        $y3   = $cpts[6*($n+1) +1];
        $ang0 = $parms[0] *pi/180.;
        $ang3 = $parms[2] *pi/180.;

        $x1 = $x0 +&max(1, $parms[1]) *cos($ang0);
        $y1 = $y0 -&max(1, $parms[1]) *sin($ang0);
        $x2 = $x3 -&max(1, $parms[3]) *cos($ang3);
        $y2 = $y3 +&max(1, $parms[3]) *sin($ang3);

        $bezier = Math::Bezier->new($x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3);

      # Compute the sum of the squared distance errors
      # for each point that is not a control point
        $sum_err = 0.;
        for ($i=$cp_indx[$n]+2; $i<$cp_indx[$n+1]; $i+=2) {
            $xp = $coords[$i];
            $yp = $coords[$i+1];
            $t  = $tvals[$i/2];
            ($xb, $yb) = $bezier->point($t);
            $sum_err  += ($xp-$xb)*($xp-$xb) +($yp-$yb)*($yp-$yb);
        }

      # Include the fit from the previous curve if the first endpoint was not "corner".
      # For the previous curve, the third control point can change angle but not length.
        if ($ptypes[$n] ne "corner" && ($n > 0 || $cform eq "closed")) {
            $n1 = ($n == 0 && $cform eq "closed") ? $#cpts -7 : 6*($n-1);
            $xp = $cpts[$n1];      # previous Bezier endpoint
            $yp = $cpts[$n1 +1];
            $x1 = $cpts[$n1 +2];
            $y1 = $cpts[$n1 +3];
            $x2 = $cpts[$n1 +4];
            $y2 = $cpts[$n1 +5];
            $d  = sqrt(($x0-$x2)*($x0-$x2) +($y0-$y2)*($y0-$y2));
            $x2 = $x0 -$d *cos($ang0);
            $y2 = $y0 +$d *sin($ang0);

            $bezier = Math::Bezier->new($xp, $yp, $x1, $y1, $x2, $y2, $x0, $y0);

            $n1 = ($n == 0 && $cform eq "closed") ? $#cp_indx -1 : $n-1;
            for ($i=$cp_indx[$n1]+2; $i<$cp_indx[$n1+1]; $i+=2) {
                $xp = $coords[$i];
                $yp = $coords[$i+1];
                $t  = $tvals[$i/2];
                ($xb, $yb) = $bezier->point($t);
                $sum_err  += ($xp-$xb)*($xp-$xb) +($yp-$yb)*($yp-$yb);
            }
        }

      # Include the fit from the next curve if the second endpoint was not "corner".
      # For the next curve, the second control point can change angle but not length.
        if ($ptypes[$n+1] ne "corner" && ($n+1 < $#cp_indx || $cform eq "closed")) {
            $n1 = ($n+1 == $#cp_indx && $cform eq "closed") ? 6 : 6*($n+2);
            $xp = $cpts[$n1];      # next Bezier endpoint
            $yp = $cpts[$n1 +1];
            $x1 = $cpts[$n1 -4];
            $y1 = $cpts[$n1 -3];
            $x2 = $cpts[$n1 -2];
            $y2 = $cpts[$n1 -1];
            $d  = sqrt(($x3-$x1)*($x3-$x1) +($y3-$y1)*($y3-$y1));
            $x1 = $x3 +$d *cos($ang3);
            $y1 = $y3 -$d *sin($ang3);

            $bezier = Math::Bezier->new($x3, $y3, $x1, $y1, $x2, $y2, $xp, $yp);

            $n1 = ($n+1 == $#cp_indx && $cform eq "closed") ? 0 : $n+1;
            for ($i=$cp_indx[$n1]+2; $i<$cp_indx[$n1+1]; $i+=2) {
                $xp = $coords[$i];
                $yp = $coords[$i+1];
                $t  = $tvals[$i/2];
                ($xb, $yb) = $bezier->point($t);
                $sum_err  += ($xp-$xb)*($xp-$xb) +($yp-$yb)*($yp-$yb);
            }
        }
        return $sum_err;
    }
}


#
# Subroutine get_fval
#   This routine allows the multidimensional minimization subroutine
#   amoeba to be used with multiple functions for different purposes.
#
sub get_fval {
    my ($fname, @pr) = @_;
    my ($fval);

    if ($fname eq "max_dist") {
        $fval = &max_dist(@pr);
    } elsif ($fname eq "curve_error") {
        $fval = &curve_error(@pr);
    } elsif ($fname eq "curve_error2") {
        $fval = &curve_error2(@pr);
    }
    return $fval;
}


###########################################################################
#
#   Multidimensional minimization of a function.
#   Inputs are:
#    @p     -- inputs, one set per row
#    @y     -- function values for each set of inputs
#    $ndim  -- number of input dimensions
#    $tol   -- fractional convergence tolerance to be achieved
#    $fname -- name of function being minimized
#
#   Solution method is the downhill simplex method of Nelder and Mead.
#   Code adapted from Fortran to Perl from Numerical Recipes-- The Art of
#   Scientific Computing, section 10.4.  The ndim+1 rows of the matrix p
#   are the vectors that are the vertices of the starting simplex.  The
#   vector y contains the function values for those starting vertices.
#   The subroutine returns the best final point, its function value, and
#   the number of iterations required to converge.
#
sub amoeba {
    my ($p_ref, $y_ref, $ndim, $tol, $fname) = @_;
    my @p = @{ $p_ref };
    my @y = @{ $y_ref };

    my ($alpha, $beta, $gamma, $i, $ihi, $ilo, $inhi, $iter, $itmax,
        $j, $mpts, $rtol, $ypr, $yprr,
        @pbar, @pr, @prr,
       );

    $alpha = 1.0;      # parameter defining expansions or contractions
    $beta  = 0.5;      # parameter defining expansions or contractions
    $gamma = 2.0;      # parameter defining expansions or contractions
    $itmax = 500;      # maximum number of iterations
    $mpts  = $ndim +1; # number of points in the simplex
    $iter  = 0;

    while ($iter < $itmax) {

      # Determine which point is highest (worst), next highest, and lowest (best)
        $ilo = 0;
        if ($y[0] > $y[1]) {
            $ihi  = 0;
            $inhi = 1;
        } else {
            $ihi  = 1;
            $inhi = 0;
        }
        for ($i=0; $i<$mpts; $i++) {         # Loop over pts in the simplex
            $ilo = $i if ($y[$i] < $y[$ilo]);
            if ($y[$i] > $y[$ihi]) {
                $inhi = $ihi;
                $ihi  = $i;
            } elsif ($y[$i] > $y[$inhi]) {
                $inhi = $i if ($i != $ihi);
            }
        }
    
      # Return if fit found and no variation
        if (abs($y[$ihi]) == 0. && abs($y[$ilo]) == 0.) {
            return ($p[$ilo], $y[$ilo], $iter);
        }

      # Compute fractional range from highest to lowest and return if satisfactory
        $rtol = 2. * abs($y[$ihi]-$y[$ilo])/(abs($y[$ihi])+abs($y[$ilo]));
        if ($rtol < $tol) {
            return ($p[$ilo], $y[$ilo], $iter);
        }

      # Begin a new iteration. Compute the vector average of all points except
      # the highest, i.e. the center of the "face" of the simplex across from the
      # high point. The algorithm will explore along the ray from the high point
      # through that center.
        $iter++;
        if ($iter == $itmax) {
          # print "Warning-- Subroutine amoeba exceeding maximum iterations.\n";
            return ($p[$ilo], $y[$ilo], $iter);
        }
        for ($j=0; $j<$ndim; $j++) {
            $pbar[$j] = 0.;
        }
        for ($i=0; $i<$mpts; $i++) {
            if ($i != $ihi) {
                for ($j=0; $j<$ndim; $j++) {
                    $pbar[$j] += $p[$i][$j];
                }
            }
        }
        for ($j=0; $j<$ndim; $j++) {
            $pbar[$j] /= $ndim;

          # Extrapolate by a factor alpha through the face, i.e. reflect the
          # simplex from the high point
            $pr[$j] = (1.+$alpha)*$pbar[$j] -$alpha*$p[$ihi][$j];
        }
        $ypr = &get_fval($fname, @pr);       # Evaluate function at reflected point
        if ($ypr <= $y[$ilo]) {              # Result is better than best point
            for ($j=0; $j<$ndim; $j++) {     # Try additional extrapolation by gamma
                $prr[$j] = $gamma*$pr[$j] +(1.-$gamma)*$pbar[$j];
            }
            $yprr = &get_fval($fname, @prr); # Evaluate function at new point
            if ($yprr < $y[$ilo]) {          # Additional extrapolation succeeded
                for ($j=0; $j<$ndim; $j++) { # Replace high point
                    $p[$ihi][$j] = $prr[$j];
                }
                $y[$ihi] = $yprr;
            } else {                         # Additional extrapolation failed
                for ($j=0; $j<$ndim; $j++) { # Can still use reflected point
                    $p[$ihi][$j] = $pr[$j];
                }
                $y[$ihi] = $ypr;
            }
        } elsif ($ypr >= $y[$inhi]) {        # Reflected pt worse than second-highest
            if ($ypr < $y[$ihi]) {           # If better than highest, then
                for ($j=0; $j<$ndim; $j++) { # Replace highest point
                    $p[$ihi][$j] = $pr[$j];
                }
                $y[$ihi] = $ypr;
            }
            for ($j=0; $j<$ndim; $j++) {     # Look for intermediate lower point
                                             # by contracting simplex along one dimension
                $prr[$j] = $beta*$p[$ihi][$j] +(1.-$beta)*$pbar[$j];
            }
            $yprr = &get_fval($fname, @prr); # Evaluate function at contracted point
            if ($yprr < $y[$ihi]) {          # Contraction is an improvement
                for ($j=0; $j<$ndim; $j++) { # Replace high point
                    $p[$ihi][$j] = $prr[$j];
                }
                $y[$ihi] = $yprr;
            } else {                         # Can't seem to get rid of high point
                for ($i=0; $i<$mpts; $i++) { # Try contraction around best point
                    if ($i != $ilo) {
                        for ($j=0; $j<$ndim; $j++) {
                            $pr[$j]    = 0.5*($p[$i][$j]+$p[$ilo][$j]);
                            $p[$i][$j] = $pr[$j];
                        }
                        $y[$i] = &get_fval($fname, @pr);
                    }
                }
            }
        } else {                          # Original reflection gives middling point
            for ($j=0; $j<$ndim; $j++) {  # Replace old high point and continue
                $p[$ihi][$j] = $pr[$j];
            }
            $y[$ihi] = $ypr;
        }
    }
}


1;
