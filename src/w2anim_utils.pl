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
# Clipping subroutines:
#   clip_profile
#
# Trig calculation subroutines:
#   make_shape_coords
#   find_rect_from_shape
#   find_rect_from_poly
#   resize_shape
#   smallest_circle
#   max_dist
#   amoeba
#

use strict;
use warnings;
use diagnostics;
use Math::Trig 'pi';

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
    return int(abs($_[0]) + 0.5) * ($_[0] < 0 ? -1 : 1);
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
        $npts = ($#coords + 1)/2;
    } else {
        return ();
    }

#   Perform the rotation
    if ($ang != 0) {
        @new_coords = ();
        for ($i=0; $i<$npts; $i++) {
            $x = $coords[2*$i];
            $y = $coords[2*$i+1];
            $d = sqrt($x*$x + $y*$y);
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
            $x =  $d *cos(($ang2 + $ang) *pi/180.);
            $y = -$d *sin(($ang2 + $ang) *pi/180.);
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
    $npts   = ($#coords + 1)/2.;
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
    $npts   = ($#coords + 1)/2.;
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
            $d = sqrt(($x-$xo)*($x-$xo) + ($y-$yo)*($y-$yo));
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
            $d = sqrt(($x-$xo)*($x-$xo) + ($y-$yo)*($y-$yo));
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
    $npts   = ($#coords + 1)/2.;
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
            $d = sqrt(($x-$xa)*($x-$xa) + ($y-$ya)*($y-$ya));
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
        $d = sqrt(($x-$xa)*($x-$xa) + ($y-$ya)*($y-$ya));
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
            $d = sqrt(($x-$xa)*($x-$xa) + ($y-$ya)*($y-$ya));
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


{
    my (@coords);   # Share among several subroutines

#   Function to begin process of finding the center of the smallest circle
#   that encompasses a set of points.
    sub smallest_circle {
        (@coords) = @_;
        my ($best_ref, $i, $iter, $maxx, $maxy, $minx, $miny, $npts, $r, $x, $y,
            @best, @p, @v,
           );

        $minx = $maxx = $coords[0];
        $miny = $maxy = $coords[1];
        $npts = ($#coords + 1)/2;
        for ($i=1; $i<$npts; $i++) {
            $minx = $coords[2*$i]   if ($minx > $coords[2*$i]  );
            $maxx = $coords[2*$i]   if ($maxx < $coords[2*$i]  );
            $miny = $coords[2*$i+1] if ($miny > $coords[2*$i+1]);
            $maxy = $coords[2*$i+1] if ($maxy < $coords[2*$i+1]);
        }

    #   Initial guess of center of circle, and two nearby points
        $p[0][0] = $x = ($minx + $maxx)/2.;
        $p[0][1] = $y = ($miny + $maxy)/2.;
        $v[0]    = &max_dist( @{ $p[0] } );

        $p[1][0] = $x-4;
        $p[1][1] = $y-4;
        $v[1]    = &max_dist( @{ $p[1] } );

        $p[2][0] = $x+4;
        $p[2][1] = $y-4;
        $v[2]    = &max_dist( @{ $p[2] } );

        ($best_ref, $r, $iter) = &amoeba(\@p, \@v, 2, 0.00001);
        @best = @{ $best_ref };
        return ($best[0], $best[1], $r);
    }


#   Function to find greatest distance (radius) from a point
    sub max_dist {
        my (@pt) = @_;
        my ($i, $maxr, $n, $r, $x, $xo, $y, $yo);

        $maxr = 0;
        $n    = ($#coords + 1)/2;
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


###########################################################################
#
#   Multidimensional minimization of a function (max_dist, here).
#   Inputs are:
#    @p    -- inputs, one set per row
#    @y    -- function values for each set of inputs
#    $ndim -- number of input dimensions
#    $tol  -- fractional convergence tolerance to be achieved
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
        my ($p_ref, $y_ref, $ndim, $tol) = @_;
        my @p = @{ $p_ref };
        my @y = @{ $y_ref };

        my ($alpha, $beta, $gamma, $i, $ihi, $ilo, $inhi, $iter, $itmax,
            $j, $mpts, $nmax, $rtol, $ypr, $yprr,
            @pbar, @pr, @prr,
           );

        $nmax  = 20;        # maximum number of dimensions
        $alpha = 1.0;       # parameter defining expansions or contractions
        $beta  = 0.5;       # parameter defining expansions or contractions
        $gamma = 2.0;       # parameter defining expansions or contractions
        $itmax = 500;       # maximum number of iterations
        $mpts  = $ndim + 1; # number of points in the simplex
        $iter  = 0;

        while ($iter < $itmax) {

    #       Determine which point is highest (worst), next highest, and lowest (best)
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
    
    #       Compute fractional range from highest to lowest and return if satisfactory
            $rtol = 2. * abs($y[$ihi]-$y[$ilo])/(abs($y[$ihi])+abs($y[$ilo]));
            if ($rtol < $tol) {
                return ($p[$ilo], $y[$ilo], $iter);
            }

    #       Begin a new iteration. Compute the vector average of all points except
    #       the highest, i.e. the center of the "face" of the simplex across from the
    #       high point. The algorithm will explore along the ray from the high point
    #       through that center.
            $iter++;
            if ($iter == $itmax) {
                print "Warning-- Subroutine amoeba exceeding maximum iterations.\n";
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

    #           Extrapolate by a factor alpha through the face, i.e. reflect the
    #           simplex from the high point
                $pr[$j] = (1.+$alpha)*$pbar[$j] -$alpha*$p[$ihi][$j];
            }
            $ypr = &max_dist( @pr );             # Evaluate function at reflected point
            if ($ypr <= $y[$ilo]) {              # Result is better than best point
                for ($j=0; $j<$ndim; $j++) {     # Try additional extrapolation by gamma
                    $prr[$j] = $gamma*$pr[$j] +(1.-$gamma)*$pbar[$j];
                }
                $yprr = &max_dist( @prr );       # Evaluate function at new point
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
                $yprr = &max_dist( @prr );       # Evaluate function at contracted point
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
                            $y[$i] = &max_dist( @pr );
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
}


1;
