############################################################################
#
#  W2 Animator
#  Data Input and Manipulation Routines
#  Copyright (c) 2022-2024, Stewart A. Rounds
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
# Subroutines included:
#
# Read and scan files:
#   scan_profile
#   read_profile
#   scan_release_rates
#   read_release_rates
#   determine_ts_type
#   read_timeseries
#
# Unit conversions for datasets:
#   convert_timeseries
#   convert_slice_data
#   convert_tdmap_data
#
# Compute profile and reformat:
#   compute_pstat_from_slice
#
# Goodness-of-fit statistics
#   get_ts_stats
#   get_stats_ref_profile
#   get_stats_single_profile
#

use strict;
use warnings;
use diagnostics;

# Global conversion types
our @conv_types = ("None",
                   "degC to degF",
                   "degF to degC",
                   "m to ft",
                   "ft to m",
                   "cms to cfs",
                   "cfs to cms",
                   "cfs to kcfs",
                   "mg/L to ug/L",
                   "ug/L to mg/L",
                   "days to hours",
                   "hours to days",
                   "Custom",
                  );

# Other global variables
our ( @mon_names, %grid,
    );


############################################################################
#
# Scan a profile data file.
# The file should contain a time-series of water-surface elevations
# along with a set of elevation- or depth-specific data values.
# The file should contain header information specifying the measurement
# units of the elevations or depths and data values, along with the
# measurement elevations or depths.
#
# This subroutine returns a file-integrity indicator and some metadata.
# Some other checks are left for the routine that reads the whole file.
#
sub scan_profile {
    my ($parent, $infile) = @_;
    my (
        $date_found, $date_only, $fh, $field, $line, $n, $pos, $status,
        $value,
        %meta,
       );

    $n = 0;
    $status = "okay";
    %meta   = ();

#   Open the profile data file:
    open ($fh, $infile) or
        return &pop_up_error($parent, "Unable to open profile data file:\n$infile");

#   Start by reading the expected metadata:
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/,+$//;
        ($date_found, $date_only) = &found_date($line);

#       If not a date input, then read the profile's metadata
        last if ($date_found);
        $pos   = index($line, ",");
        $field = substr($line, 0, $pos);
        $value = substr($line, $pos +1);
        $value =~ s/^\s+//;

        if ($field =~ /DataType/i) {
            $status = "bad" if ($value !~ /ProfileData|TemperatureProfile/i);
            if ($value =~ /TemperatureProfile/i) {
                $meta{parm} = "Temperature";
            }
            $n++;
        } elsif ($field =~ /Parameter/i) {
            $meta{parm} = $value;
        } elsif ($field =~ /ElevOrDepth/i) {
            $status = "bad" if ($value !~ /(Elevation|Depth)/i);
            $n++;
        } elsif ($field =~ /ElevUnits/i) {
            $status = "bad" if ($value !~ /^(ft|foot|feet|m|meter|meters)$/i);
            $n++;
        } elsif ($field =~ /InputUnits|InputDegrees/i) {
            if ($field =~ /InputDegrees/i) {
                $status = "bad" if ($value !~ /(Celsius|Fahrenheit)/i);
            }
            $n++;
        } elsif ($field =~ /Ytype/i) {
            $meta{ytype} = ucfirst($value) if ($value =~ /^(Elevation|Depth)$/i);
        } elsif ($field =~ /Yunits/i) {
            if ($value =~ /^(ft|foot|feet|m|meter|meters)$/i) {
                $meta{yunits} = ($value =~ /(ft|foot|feet)/i) ? "feet" : "meters";
            }
        } elsif ($field =~ /Ymin/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{ymin} = $value) =~ s/[^-0-9\.]//g;
            }
        } elsif ($field =~ /Ymax/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{ymax} = $value) =~ s/[^-0-9\.]//g;
            }
        } elsif ($field =~ /Ymajor/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{ymajor} = $value) =~ s/[^0-9\.]//g;
            }
        } elsif ($field =~ /ParmUnits|WTunits/i) {
            if ($field =~ /WTunits/i) {
                $meta{parm_units} = ucfirst(lc($value)) if ($value =~ /^(Celsius|Fahrenheit)$/i);
            } else {
                $meta{parm_units} = $value;
            }
        } elsif ($field =~ /ParmMin|WTmin/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{parm_min} = $value) =~ s/[^-0-9\.]//g;
            }
        } elsif ($field =~ /ParmMax|WTmax/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{parm_max} = $value) =~ s/[^-0-9\.]//g;
            }
        } elsif ($field =~ /ParmMajor|WTmajor/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{parm_major} = $value) =~ s/[^0-9\.]//g;
            }
        } elsif ($field =~ /ElevationOrDepth/i) {
            $n++;
        }
    }
    $status = "bad" if ($n < 5);

#   Close the profile data file:
    close ($fh)
        or &pop_up_info($parent, "Unable to close profile data file:\n$infile");

    return ($status, %meta);
}


############################################################################
#
# Read a somewhat self-describing vertical profile data file in csv format.
#
# Routine returns a hash with metadata and data.
#
sub read_profile {
    my ($parent, $infile) = @_;
    my (
        $d, $date_found, $date_only, $dt, $el_units, $elev_or_depth, $fh,
        $field, $h, $i, $line, $m, $mi, $n, $parm, $parm_units, $pos,
        $sorted, $value, $ws_elev, $y,

        @elv_depth, @estimated, @indx, @pdata,

        %surf_elev, %profile_data, %profile,
       );

    $n = 0;
    $parm_units = $parm = "";
    @elv_depth = @estimated    = @pdata   = ();
    %surf_elev = %profile_data = %profile = ();

#   Open the profile data file:
    open ($fh, $infile) or
        return &pop_up_error($parent, "Unable to open profile data file:\n$infile");

#   Start by reading the expected metadata:
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/,+$//;
        ($date_found, $date_only) = &found_date($line);

#       If not a date input, then read the profile's metadata
        if (! $date_found) {
            $pos   = index($line, ",");
            $field = substr($line, 0, $pos);
            $value = substr($line, $pos +1);
            $value =~ s/^\s+//;

            if ($field =~ /DataType/i) {
                if ($value !~ /ProfileData|TemperatureProfile/i) {
                    &pop_up_info($parent, "DataType should be ProfileData or TemperatureProfile:\n$infile");
                } elsif ($value =~ /TemperatureProfile/i) {
                    $parm = "Temperature";
                }
                $n++;
            } elsif ($field =~ /Parameter/i) {
                $parm = $value;
            } elsif ($field =~ /ElevOrDepth/i) {
                if ($value !~ /^(Elevation|Depth)$/i) {
                    &pop_up_error($parent, "ElevOrDepth must be Elevation or Depth:\n$infile");
                    return;
                }
                $elev_or_depth = lc($value);
                $n++;
            } elsif ($field =~ /ElevUnits/i) {
                if ($value !~ /^(ft|foot|feet|m|meter|meters)$/i) {
                    &pop_up_error($parent, "ElevUnits must be feet or meters:\n$infile");
                    return;
                }
                $el_units = ($value =~ /(ft|foot|feet)/i) ? "feet" : "meters";
                $n++;
            } elsif ($field =~ /InputUnits|InputDegrees/i) {
                if ($field =~ /InputDegrees/i && $value !~ /^(Celsius|Fahrenheit)$/i) {
                    &pop_up_error($parent, "InputDegrees must be Celsius or Fahrenheit:\n$infile");
                    return;
                }
                $parm_units = ucfirst(lc($value));
                $n++;
            } elsif ($field =~ /ElevationOrDepth/i) {
                @elv_depth = split(/,/, $line);
                shift @elv_depth;
                shift @elv_depth;
                @estimated = ();
                for ($i=0; $i<=$#elv_depth; $i++) {
                    if ($elv_depth[$i] =~ /e$/i) {
                        push (@estimated, 1);
                        $elv_depth[$i] =~ s/e$//i;
                    } else {
                        push (@estimated, 0);
                    }
                }
                $n++;
            }

#       Otherwise, data have been found.
#       Expect date, then water-surface elevation, then parameter values at the
#         specified depths or elevations.
        } else {
            @pdata   = split(/,/, $line);
            $dt      = shift(@pdata);
            $ws_elev = shift(@pdata);
            if ($parm eq "Temperature" && $parm_units eq "Fahrenheit") {
                for ($i=0; $i<=$#pdata; $i++) {
                    if ($pdata[$i] ne "na") {
                        $pdata[$i] = ($pdata[$i] -32)/1.8;
                    }
                }
            }
            if ($date_only) {
                ($m, $d, $y) = &parse_date($dt, $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($dt, $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $surf_elev{$dt}    = $ws_elev;
            $profile_data{$dt} = [ @pdata ];
        }
    }

#   Close the profile data file:
    close ($fh)
        or &pop_up_info($parent, "Unable to close profile data file:\n$infile");

#   Several of the inputs are critical.  Exit early if the file didn't include them.
    if ($n < 5) {
        return &pop_up_error($parent, "The profile data file is incomplete:\n$infile");
    }

#   Modify elevations to be in meters
    if ($el_units eq "feet") {
        for ($i=0; $i<=$#elv_depth; $i++) {
            $elv_depth[$i] /= 3.28084;
        }
        foreach $dt (keys %surf_elev) {
            if ($surf_elev{$dt} ne "na") {
                $surf_elev{$dt} /= 3.28084;
            }
        }
    }

#   Clean up parameter units that were converted
    if ($parm eq "Temperature" && $parm_units eq "Fahrenheit") {
        $parm_units = "Celsius";
    }

#   Ensure that points are sorted top to bottom
    if ($elev_or_depth eq "elevation") {
        ($sorted, @indx) = &get_sort_index("descending", @elv_depth);
        if (&list_match("-1", @indx) >= 0) {
            &pop_up_info($parent, "Any repeated elevation columns will be skipped:\n$infile");
        }
        if (! $sorted) {
            @elv_depth = &rearrange_array(\@elv_depth, \@indx);
            @estimated = &rearrange_array(\@estimated, \@indx);
            foreach $dt (keys %profile_data) {
                @pdata = @{ $profile_data{$dt} };
                @pdata = &rearrange_array(\@pdata, \@indx);
                $profile_data{$dt} = [ @pdata ];
            }
        }
        $profile{elevations} = [ @elv_depth ];
    } else {
        ($sorted, @indx) = &get_sort_index("ascending", @elv_depth);
        if (&list_match("-1", @indx) >= 0) {
            &pop_up_info($parent, "Any repeated depth columns will be skipped:\n$infile");
        }
        if (! $sorted) {
            @elv_depth = &rearrange_array(\@elv_depth, \@indx);
            @estimated = &rearrange_array(\@estimated, \@indx);
            foreach $dt (keys %profile_data) {
                @pdata = @{ $profile_data{$dt} };
                @pdata = &rearrange_array(\@pdata, \@indx);
                $profile_data{$dt} = [ @pdata ];
            }
        }
        $profile{depths} = [ @elv_depth ];
    }

#   Populate the rest of the returning hash
    $profile{parm}       = $parm;
    $profile{parm_units} = $parm_units;
    $profile{elv_dep}    = $elev_or_depth;
    $profile{estimated}  = [ @estimated ];
    $profile{ws_elev}    = { %surf_elev };
    $profile{pdata}      = { %profile_data };
    $profile{daily}      = $date_only;

    return %profile;
}


############################################################################
#
# Scan an outlet flow file containing dam release rates from multiple
# outlets.  Read and return some metadata.  File format is csv.
#
sub scan_release_rates {
    my ($parent, $infile) = @_;
    my (
        $date_found, $date_only, $fh, $field, $line, $n, $pos, $status,
        $value,
        %meta,
       );

    $n = 0;
    $status = "okay";
    %meta   = ();

#   Open the data file:
    open ($fh, $infile) or
        return &pop_up_error($parent, "Unable to open release rate file:\n$infile");

#   Start by reading the expected metadata:
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/,+$//;
        ($date_found, $date_only) = &found_date($line);

#       If not a date input, then read the profile's metadata
        last if ($date_found);
        $pos   = index($line, ",");
        $field = substr($line, 0, $pos);
        $value = substr($line, $pos +1);
        $value =~ s/^\s+//;

        if ($field =~ /DataType/i) {
            $status = "bad" if ($value !~ /ReleaseRates/i);
            $n++;
        } elsif ($field =~ /ElevUnits/i) {
            $status = "bad" if ($value !~ /(ft|foot|feet|m|meter|meters)/i);
            $n++;
        } elsif ($field =~ /LineWidthUnits/i) {
            $status = "bad" if ($value !~ /(ft|foot|feet|m|meter|meters)/i);
            $n++;
        } elsif ($field =~ /InputFlowUnits/i) {
            $status = "bad" if ($value !~ /(cfs|cubic feet per second|cms|cubic meters per second)/i);
            $n++;
        } elsif ($field =~ /NumOutlets/i) {
            $status = "bad" if ($value <= 0 || $value !~ /[1-9]/);
            $n++;
        } elsif ($field =~ /Algorithm/i) {
            $n++;
        } elsif ($field =~ /OutletName/i) {
            $n++;
        } elsif ($field =~ /CenterlineElev/i) {
            $n++;
        } elsif ($field =~ /OutletType/i) {
            $n++;
        } elsif ($field =~ /LineWidth/i) {
            $n++;
        } elsif ($field =~ /FlowUnits/i) {
            if ($value =~ /(cfs\/ft|cms\/m|ft\/s|m\/s)/i) {
                $meta{qunits} = $value;
            }
        } elsif ($field =~ /FlowMax/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{qmax} = $value) =~ s/[^-0-9\.]//g;
            }
        } elsif ($field =~ /FlowMajor/i) {
            if ($value =~ /[0-9]+/) {
                ($meta{qmajor} = $value) =~ s/[^0-9\.]//g;
            }
        }
    }
    $status = "bad" if ($n < 10);

#   Close the release rate file:
    close ($fh)
        or &pop_up_info($parent, "Unable to close release rate file:\n$infile");

    return ($status, %meta);
}


############################################################################
#
# Read a somewhat self-describing file with dam release rates from
# multiple outlets.  File format is csv.
#
# Routine returns a hash with metadata and data.
#
sub read_release_rates {
    my ($parent, $infile) = @_;
    my (
        $bad_data, $d, $date_found, $date_only, $dt, $el_units, $fh, $field,
        $flow_units, $h, $i, $line, $lw_units, $m, $mi, $n, $nout, $pos,
        $value, $y,

        @estr, @flows, @kbsw, @ktsw, @lw, @names, @sink_type, @sw_alg,

        %qdata, %rel_data,
       );

    $el_units   = "feet";
    $flow_units = "cfs";
    $lw_units   = "meters";

    $n     = 0;
    $nout  = 0;
    @estr  = @flows = @kbsw = @ktsw = @lw = @names = @sink_type = @sw_alg = ();
    %qdata = %rel_data = ();

#   Open the data file:
    open ($fh, $infile) or
        return &pop_up_error($parent, "Unable to open release rate file:\n$infile");

#   Start by reading the expected metadata:
    while (defined( $line = <$fh> )) {
        chomp $line;
        $line =~ s/,+$//;
        ($date_found, $date_only) = &found_date($line);

#       If not a date input, then read the profile's metadata
        if (! $date_found) {
            $pos   = index($line, ",");
            $field = substr($line, 0, $pos);
            $value = substr($line, $pos +1);
            $value =~ s/^\s+//;

            if ($field =~ /DataType/i) {
                if ($value !~ /ReleaseRates/i) {
                    &pop_up_info($parent, "DataType should be ReleaseRates:\n$infile");
                }
                $n++;
            } elsif ($field =~ /ElevUnits/i) {
                if ($value !~ /(ft|foot|feet|m|meter|meters)/i) {
                    &pop_up_error($parent, "ElevUnits must be feet or meters:\n$infile");
                    return;
                }
                $el_units = ($value =~ /(ft|foot|feet)/i) ? "feet" : "meters";
                $n++;
            } elsif ($field =~ /LineWidthUnits/i) {
                if ($value !~ /(ft|foot|feet|m|meter|meters)/i) {
                    &pop_up_error($parent, "LineWidthUnits must be feet or meters:\n$infile");
                    return;
                }
                $lw_units = ($value =~ /(ft|foot|feet)/i) ? "feet" : "meters";
                $n++;
            } elsif ($field =~ /InputFlowUnits/i) {
                if ($value !~ /(cfs|cubic feet per second|cms|cubic meters per second)/i) {
                    &pop_up_error($parent, "InputFlowUnits must be cfs or cms:\n$infile");
                    return;
                }
                $flow_units = ($value =~ /(cfs|cubic feet per second)/i) ? "cfs" : "cms";
                $n++;
            } elsif ($field =~ /NumOutlets/i) {
                if ($value <= 0 || $value !~ /[1-9]/) {
                    &pop_up_error($parent, "NumOutlets must be 1 or more:\n$infile");
                    return;
                }
                $nout = $value +1-1;
                $n++;
            } elsif ($field =~ /Algorithm/i) {
                @sw_alg = split(/,/, substr($line, $pos +1));
                $n++;
            } elsif ($field =~ /OutletName/i) {
                @names = split(/,/, substr($line, $pos +1));
                $n++;
            } elsif ($field =~ /CenterlineElev/i) {
                @estr = split(/,/, substr($line, $pos +1));
                $n++;
            } elsif ($field =~ /OutletType/i) {
                @sink_type = split(/,/, substr($line, $pos +1));
                $n++;
            } elsif ($field =~ /LineWidth/i) {
                @lw = split(/,/, substr($line, $pos +1));
                $n++;
            } elsif ($field =~ /TopLayerLimit/i) {
                @ktsw = split(/,/, substr($line, $pos +1));
            } elsif ($field =~ /BottomLayerLimit/i) {
                @kbsw = split(/,/, substr($line, $pos +1));
            }

#       Otherwise, data have been found.
#       Expect date, then release rates for each outlet
        } else {
            @flows = split(/,/, $line);
            $dt    = shift(@flows);
            for ($i=0; $i<=$#flows; $i++) {
                if ($flows[$i] eq "" || $flows[$i] =~ /^\s+$/) {
                    $flows[$i] = "na";
                }
            }
            if ($date_only) {
                ($m, $d, $y) = &parse_date($dt, $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($dt, $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $qdata{$dt} = [ @flows ];
        }
    }

#   Close the release rate file:
    close ($fh)
        or &pop_up_info($parent, "Unable to close release rate file:\n$infile");

#   Several of the inputs are critical.  Exit early if the file didn't include them.
    if ($n < 10) {
        return &pop_up_error($parent, "Outlet release rate file is incomplete:\n$infile");
    }

#   Some post-read QA
    if ($nout == 0) {
        &pop_up_error($parent, "The number of outlets (NumOutlets) must be specified:\n$infile");
        return;
    }
    $bad_data = 0;
    $bad_data = 1 if ($#estr      +1 < $nout);
    $bad_data = 1 if ($#sink_type +1 < $nout);
    $bad_data = 1 if ($#lw        +1 < $nout);
    for ($i=0; $i<$nout; $i++) {
        $bad_data = 1 if ($estr[$i] < 0 || $estr[$i] !~ /[0-9]/);
    }
    if ($bad_data) {
        &pop_up_error($parent, "Check release rate file for negative numbers or\n"
                             . "insufficient number of entries in header:\n$infile");
        return;
    }
    for ($i=0; $i<$nout; $i++) {
        if ($sink_type[$i] !~ /^(point|line)$/i) {
            &pop_up_error($parent, "OutletType must be point or line:\n$infile");
            return;
        }
        $sink_type[$i] = lc($sink_type[$i]);
        if ($sink_type[$i] eq "line" && $lw[$i] <= 0) {
            &pop_up_error($parent, "LineWidth must be > zero for each line sink:\n$infile");
            return;
        }
        $lw[$i]   = 0 if ($sink_type[$i] eq "point");
        $ktsw[$i] = 2 if (! defined($ktsw[$i]) || $ktsw[$i] < 2);
        $kbsw[$i] = 2 if (! defined($kbsw[$i]) || $kbsw[$i] < 2);
    }

#   Ensure that the withdrawal algorithm is either "W2orig" or "LibbyDam"
    for ($i=0; $i<$nout; $i++) {
        if (! defined($sw_alg[$i])) {
            $sw_alg[$i] = "W2orig";
            next;
        }
        $sw_alg[$i] = ($sw_alg[$i] =~ /Libby/i) ? "LibbyDam" : "W2orig";
    }

#   Modify line widths to be in meters
    if ($lw_units eq "feet") {
        for ($i=0; $i<$nout; $i++) {
            $lw[$i] /= 3.28084;
        }
    }

#   Modify elevations to be in meters
    if ($el_units eq "feet") {
        for ($i=0; $i<$nout; $i++) {
            $estr[$i] /= 3.28084;
        }
    }

#   Modify flows to be in cms
    if ($flow_units eq "cfs") {
        foreach $dt (keys %qdata) {
            @flows = @{ $qdata{$dt} };
            for ($i=0; $i<=$#flows; $i++) {
                if ($flows[$i] ne "na") {
                    $flows[$i] /= 35.31467;
                }
            }
            $qdata{$dt} = [ @flows ];
        }
    }

    $rel_data{nout}   = $nout;
    $rel_data{sw_alg} = [ @sw_alg ];
    $rel_data{names}  = [ @names  ];
    $rel_data{estr}   = [ @estr   ];
    $rel_data{lw}     = [ @lw     ];
    $rel_data{ktsw}   = [ @ktsw   ];
    $rel_data{kbsw}   = [ @kbsw   ];
    $rel_data{qdata}  = { %qdata  };
    $rel_data{daily}  = $date_only;

    return %rel_data;
}


############################################################################
# 
# Try to determine the type of input file.  Return the best guess of the
# file type, a list of parameters, and the number of data lines.
#
# Possible file types to return:
#  "USGS getData format"
#  "Aquarius Time-Series format"
#  "Dataquery format"
#  "USGS Water Services format"
#  "USGS Data Grapher format"
#  "W2 Heat Fluxes format"
#  "W2 Daily SurfTemp.dat format"
#  "W2 Daily VolTemp.dat format"
#  "W2 Daily FlowTemp.dat format"
#  "W2 Subdaily SurfTemp2.dat format"
#  "W2 Subdaily VolTemp2.dat format"
#  "W2 Subdaily FlowTemp2.dat format"
#  "W2 TSR format"
#  "W2 Outflow CSV format"
#  "W2 Layer Outflow CSV format"
#  "W2 Water Level (wl.opt) format"
#  "CSV format"
#  "W2 CSV format"
#  "W2 column format"
#
sub determine_ts_type {
    my ($parent, $file, $hide_err) = @_;
    my (
        $count, $date_found, $date_only, $fh, $file_type, $i, $line,
        $line2, $lines_left, $nextra, $nl, $parm, $parms_found, $pos, $seg,
        @fields, @parms,
       );

    $nl = 0;
    $file_type = "";
    $hide_err  = 0 if (! defined($hide_err) || $hide_err ne "1");
    @parms     = ();

#   Open the file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open input file:\n$file");

#   Check for the USGS getData format
    $line = <$fh>;
    if ($line =~ /^\# \/\/UNITED STATES GEOLOGICAL SURVEY       https/) {
        while (defined($line = <$fh>)) {
            if ($line =~ /\# \/\/TIMESERIES IDENTIFIER=/) {
                chomp $line;
                $parms[0] = substr($line,26);
                $parms[0] =~ s/^"//;
                $parms[0] =~ s/"$//;
                next;
            }
            next if ($line =~ /^\# \/\//);
            if ($line =~ /^DATE/) {
                $line = <$fh>;
                $line = <$fh>;
                ($date_found, $date_only) = &found_date($line);
                if ($date_found) {
                    $file_type = "USGS getData format";
                }
                last;
            }
        }
        if ($file_type ne "") {
            $nl = 1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);   # push file position pointer back to beginning

#   Check for the Aquarius Time-Series format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /\#.* by AQUARIUS Time-Series /) {
        while (defined($line = <$fh>)) {
            if ($line =~ /\# Time-series identifier: /) {
                chomp $line;
                $parms[0] = substr($line,26);
                next;
            }
            next if ($line =~ /^\#/);
            if ($line =~ /^ISO 8601 UTC,Timestamp /) {
                $line = <$fh>;
                ($date_found, $date_only) = &found_date($line);
                if ($date_found) {
                    $file_type = "Aquarius Time-Series format";
                }
                last;
            }
        }
        if ($file_type ne "") {
            $nl = 1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for a Dataquery format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /^Date Time,/) {
        chomp $line;
        $line  =~ s/,+$//;
        @parms = split(/,/, substr($line,10));
        $lines_left = 10;    # look at only the first 10 lines
        while ($lines_left > 0 && defined($line = <$fh>)) {
            $lines_left--;
            chomp $line;
            $line   =~ s/,+$//;
            @fields = split(/,/, $line);
            ($date_found, $date_only) = &found_date($line);
            if ($date_found && $#parms == $#fields-1) {
                $file_type = "Dataquery format";
                last;
            }
        }
        if ($file_type ne "") {
            $nl = 1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the USGS Water Services format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /^\# ---------------------------------- WARNING ----------/) {
        while (defined($line = <$fh>)) {
            chomp $line;
            if ($line =~ /^\#\s+TS_ID\s+Parameter\s+.*Description/) {
                $pos  = index($line, "Description");
                $line = <$fh>;
                chomp $line;
                $parms[0] = substr($line,$pos);
                next;
            }
            next if ($line =~ /^\#/);
            if ($line =~ /^agency_cd\tsite_no\tdatetime\t/) {
                $file_type = "USGS Water Services format";
                last;
            }
        }
        if ($file_type ne "") {
            $nl = -1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the USGS Data Grapher format
    $line = <$fh>;
    chomp $line;
    if ($file_type eq "" && $line =~ /Data from U.S. Geological Survey \(USGS\)\.$/) {
        $count = 0;
        $lines_left = 100;    # limit search to the first 100 lines
        while ($lines_left > 0 && defined($line = <$fh>)) {
            chomp $line;
            $lines_left--;
            if ($line =~ /Table created /) {
                $count++;
                next;
            }
            if ($line =~ /Parameters:$/) {
                $count++;
                while ($lines_left > 0 && defined($line = <$fh>)) {
                    $lines_left--;
                    chomp $line;
                    $line =~ s/^\#//;
                    $line =~ s/^\s+//;
                    last if ($line eq "");
                    ($parm = $line) =~ s/ -- from .$//;
                    push (@parms, $parm);
                }
                next;
            }
            ($date_found, $date_only) = &found_date($line);
            if ($date_found) {
                $count++;
                last;
            }
        }
        if ($count == 3) {
            $file_type = "USGS Data Grapher format";
            $nl = 1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the W2 Heat Fluxes output format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /^\#Daily energy fluxes and daily mean energy ratios/) {
        while (defined($line = <$fh>)) {
            next if ($line =~ /^\#/);
            if ($line =~ /^JDAY,SEG,HRTS,ADER,EEFR,EEFN,EFLW,EFSW,EFCI,EFCO,EFBR,EFEO,EFEI,SHAD,WTDR,MWID/) {
                chomp $line;
                @parms     = split(/,/, substr($line,9));
                $file_type = "W2 Heat Fluxes format";
                last;
            }
        }
        if ($file_type ne "") {
            $nl = 0;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the W2 SurfTemp.dat, FlowTemp.dat, or VolTemp.dat format
    $line = <$fh>;
    if ($file_type eq "" && ($line =~ /^Daily mean flow, max\/mean\/min temperature/ ||
                             $line =~ /^Daily max\/mean\/min temperature/)) {
        $line2 = <$fh>;
        if ($line2 =~ /^All values except Qmean are / || $line2 =~ /^All values are /) {
            $line = <$fh>;
            $line = <$fh>;   # fourth line
            if ($line =~ /^ JDAY  SEG     Qmean    Tmax   Tmean    Tmin/
                  || $line =~ /^ JDAY  SEG    Tmax   Tmean    Tmin/) {
                if ($line2 =~ /from the surface layer/) {
                    $file_type = "W2 Daily SurfTemp.dat format";
                } elsif ($line2 =~ /are volume-weighted averages/) {
                    $file_type = "W2 Daily VolTemp.dat format";
                } elsif ($line2 =~ /are flow-weighted averages/) {
                    $file_type = "W2 Daily FlowTemp.dat format";
                }
                chomp $line;
                $nextra = (length($line) -44) /9;
                @parms  = qw(Qmean Tmax Tmean Tmin);
                $line   = substr($line,44);
                for ($i=0; $i<$nextra; $i++) {
                    push (@parms, substr($line,9*$i,9));
                }
            }
        }
        if ($file_type ne "") {
            $nl = 0;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the W2 SurfTemp2.dat, FlowTemp2.dat, or VolTemp2.dat format
    $line = <$fh>;
    if ($file_type eq "" && ($line =~ /^Subdaily flow, water temperature/ ||
                             $line =~ /^Subdaily water temperature/)) {
        $line2 = <$fh>;
        if ($line2 =~ /^All values except flow are / || $line2 =~ /^All values are /) {
            $line = <$fh>;
            $line = <$fh>;   # fourth line
            if ($line =~ /^     JDAY  SEG      FLOW    TEMP/ || $line =~ /^     JDAY  SEG    TEMP/) {
                if ($line2 =~ /from the surface layer/) {
                    $file_type = "W2 Subdaily SurfTemp2.dat format";
                } elsif ($line2 =~ /are volume-weighted averages/) {
                    $file_type = "W2 Subdaily VolTemp2.dat format";
                } elsif ($line2 =~ /are flow-weighted averages/) {
                    $file_type = "W2 Subdaily FlowTemp2.dat format";
                }
                chomp $line;
                $nextra = (length($line) -32) /9;
                @parms  = qw(FLOW TEMP);
                $line   = substr($line,32);
                for ($i=0; $i<$nextra; $i++) {
                    push (@parms, substr($line,9*$i,9));
                }
            }
        }
        if ($file_type ne "") {
            $nl = 0;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the W2 TSR time-series output format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /^JDAY,DLT\(s\),ELWS\(m\),T2\(C\),U/) {
        $file_type = "W2 TSR format";
        chomp $line;
        $line  =~ s/,+$//;
        @parms = split(/,/, substr($line,5));
        $nl = 0;
        $nl++ while <$fh>;
    }
    seek ($fh, 0, 0);

#   Check for the W2 Outflow time-series output format
    $line = <$fh>;
    if ($file_type eq "" && ($line =~ /^\$Flow file for segment / ||
                             $line =~ /^\$Temperature file for segment / ||
                             $line =~ /^\$Concentration file for segment / ||
                             $line =~ /^Derived constituent file for segment / ||
                             $line =~ /^\$STR WITHDRAWAL AT SEG/)) {
        $file_type = "W2 Outflow CSV format";
        if ($line =~ /^\$Concentration/ || $line =~ /^Derived/ || $line =~ /^\$STR WITHDRAWAL/) {
            $line = <$fh>;
            $line = <$fh>;   # check headers on third line
            chomp $line;
            $line  =~ s/,+$//;
            @parms = split(/,/, substr($line,5));
            $nl = 0;
        } else {
            $parm = ($line =~ /^\$Flow/) ? "Flow" : "Temperature";
            $line = <$fh>;
            $line = <$fh>;
            $line = <$fh>;   # check number of fields on fourth line
            chomp $line;
            $line  =~ s/,+$//;
            @parms = split(/,/, $line);
            shift @parms;   # remove the JDAY field
            for ($i=0; $i<=$#parms; $i++) {
                $parms[$i] = sprintf("%s%d", $parm, $i+1);
            }
            $nl = 1;
        }
        $nl++ while <$fh>;
    }
    seek ($fh, 0, 0);

#   Check for the W2 Layer Outflow CSV format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /^Flow layers file for segment /) {
        chomp $line;
        ($seg = $line) =~ s/^Flow layers file for segment (\d+)/$1/;
        $line = <$fh>;
        if ($line =~ /^Output is JDAY, total outflow, WS elev, and layer outflows starting /) {
            $file_type = "W2 Layer Outflow CSV format";
            $parms[0]  = "Total Outflow, segment " . $seg;
            $parms[1]  = "WS Elevation, segment " . $seg;
            $line = <$fh>;
            $nl   = 0;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for the W2 water-level (wl.opt) output format
    $line = <$fh>;
    if ($file_type eq "" && $line =~ /^JDAY,SEG\s+?\d+,SEG\s+?\d+,SEG\s+?\d+/) {
        $file_type = "W2 Water Level (wl.opt) format";
        chomp $line;
        $line  =~ s/,+$//;
        $line  =~ s/,SEG$//;
        @parms = split(/,/, substr($line,5));
        for ($i=0; $i<=$#parms; $i++) {
            $parms[$i] =~ s/^SEG\s+?//;    # return segments rather than "Water Level"
        }
        $nl = 0;
        $nl++ while <$fh>;
    }
    seek ($fh, 0, 0);

#   Check for a comma-delimted file with dates in the first field
    if ($file_type eq "") {
        $lines_left  = 50;    # look at only the first 50 lines
        $parms_found = 0;
        while ($lines_left > 0 && defined($line = <$fh>)) {
            $lines_left--;
            next if ($line =~ /^\#/);
            chomp $line;
            $line =~ s/,+$//;
            @fields = split(/,/, $line);
            if ($#fields >= 1 && ($fields[0] eq "DateTime" || $fields[0] eq "Date"
                                                           || $fields[0] eq "Date/Time")) {
                shift @fields;
                @parms = @fields;
                $parms_found = 1;
                next;
            }
            ($date_found, $date_only) = &found_date($line);
            if ($date_found && $#fields >= 1) {
                $file_type = "CSV format";
                shift @fields;
                if (! $parms_found || $#fields != $#parms) {
                    @parms = ();
                    for ($i=0; $i<=$#fields; $i++) {
                        $parms[$i] = sprintf("%s%d", "Parameter", $i+1);
                    }
                }
                last;
            }
        }
        if ($file_type ne "") {
            $nl = 1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for a comma-delimted W2-style input or output file
    $line = <$fh>;
    if ($file_type eq "" && substr($line,0,1) eq '$') {
        $line = <$fh>;
        $line = <$fh>;
        $line = <$fh>;    # check fourth line for number of fields
        chomp $line;
        $line =~ s/,+$//;
        @fields = split(/,/, $line);
        if ($#fields >= 1 && $fields[0] =~ /\s*\d+\.?\d?\s*/
                          && $fields[1] =~ /\s*\d+\.?\d?\s*/) {
            $file_type = "W2 CSV format";
            @parms     = @fields;
            shift @parms;   # remove the JDAY field
            for ($i=0; $i<=$#parms; $i++) {
                $parms[$i] = sprintf("%s%d", "Parameter", $i+1);
            }
        }
        if ($file_type ne "") {
            $nl = 1;
            $nl++ while <$fh>;
        }
    }
    seek ($fh, 0, 0);

#   Check for possibility of column-format W2-style input or output file
    $line = <$fh>;
    if ($file_type eq "") {
        $line = <$fh>;
        $line = <$fh>;
        $line = <$fh>;
        chomp $line;
        if (length($line) >= 16) {
            $fields[0] = substr($line,0,8);
            $fields[1] = substr($line,8,8);
            if ($#fields >= 1 && $fields[0] =~ /\s*\d+\.?\d?\s*/
                              && $fields[1] =~ /\s*\d+\.?\d?\s*/) {
                $file_type = "W2 column format";
                for ($i=1; $i<length($line)/8; $i++) {
                    if (substr($line,8*$i,8) =~ /\s*\d+\.?\d?\s*/) {
                        $parms[$i-1] = sprintf("%s%d", "Parameter", $i);
                    }
                }
                $nl = 1;
                $nl++ while <$fh>;
            }
        }
    }

#   Close the file.
    close ($fh)
        or &pop_up_info($parent, "Unable to close input file:\n$file");

#   Check for unrecognized file type.
    if ($file_type eq "" && ! $hide_err) {
        &pop_up_error($parent, "Unrecognized file type:\n$file");
    }

#   Remove leading or trailing white space
    for ($i=0; $i<=$#parms; $i++) {
        if (defined($parms[$i])) {
            $parms[$i] =~ s/^\s+//;
            $parms[$i] =~ s/\s+$//;
        }
    }
    return ($file_type, $nl, @parms);
}


############################################################################
#
#  Read a time-series data file of a particular type.
#  Possible file types are:
#   "USGS getData format"
#   "Aquarius Time-Series format"
#   "Dataquery format"
#   "USGS Water Services format"
#   "USGS Data Grapher format"
#   "CSV format"
#
#  Expect the date to be in a recognizable format and be in the first field.
#
#  Return a hash where the date keys to the data, and the date is in either
#  YYYYMMDD or YYYYMMDDHHmm format.
#
sub read_timeseries {
    my ($parent, $file, $file_type, $parm, $pbar) = @_;
    my (
        $d, $daily, $date_found, $date_only, $dt, $fh, $h, $line,
        $lines_left, $m, $mi, $missing, $nl, $pcode, $pos, $progress_bar,
        $stat, $subdaily, $ts_id, $tscode, $val, $value_field, $y,

        @fields, @parms,
        %ts_data,
       );

    $nl = 0;
    $missing      = "na";
    $value_field  = -1;
    $progress_bar = ($pbar ne "") ? 1 : 0;

#   Open the data file
    open ($fh, $file) or
        return &pop_up_error($parent, "Unable to open time-series data file:\n$file");

#   Read the data file
    if ($file_type eq "USGS getData format") {
        $line = <$fh>;
        if ($line !~ /^\# \/\/UNITED STATES GEOLOGICAL SURVEY       https/) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        while (defined($line = <$fh>)) {
            chomp $line;
            if ($line =~ /^\# \/\/TIMESERIES IDENTIFIER=/) {
                $ts_id = substr($line,26);
                $ts_id =~ s/^"//;
                $ts_id =~ s/"$//;
                if ($ts_id ne $parm) {
                    return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
                }
            }
            next if ($line =~ /^\# \/\//);
            if ($line =~ /^DATE/) {
                @fields = split(/\t/, $line);
                $value_field = &list_match("VALUE", @fields);
                if ($value_field == -1) {
                    return &pop_up_error($parent, "VALUE field not found:\n$file");
                }
                $line = <$fh>;    # skip next line
                next;
            }
            ($date_found, $date_only) = &found_date($line);
            next if (! $date_found);
            @fields = split(/\t/, $line);
            if ($date_only) {
                ($m, $d, $y) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($fields[0] . "\t" . $fields[1], $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $ts_data{$dt} = $fields[$value_field];

            $nl++;
            if ($progress_bar && $nl % 250 == 0) {
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "Aquarius Time-Series format") {
        $line = <$fh>;
        if ($line !~ /^\#.* by AQUARIUS Time-Series /) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        $subdaily = 0;
        while (defined($line = <$fh>)) {
            chomp $line;
            if ($line =~ /^\# Time-series identifier: /) {
                $ts_id = substr($line,26);
                if ($ts_id ne $parm) {
                    return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
                }
            }
            if ($line =~ /^\# Interpolation type: /) {
                $subdaily = ($line =~ /Instantaneous Values/i) ? 1 : 0;
            }
            next if ($line =~ /^\#/);
            if ($line =~ /^ISO 8601 UTC,Timestamp /) {
                @fields = split(/,/, $line);
                $value_field = &list_match("Value", @fields);
                if ($value_field == -1) {
                    return &pop_up_error($parent, "VALUE field not found:\n$file");
                }
                next;
            }
            ($date_found, $date_only) = &found_date($line);
            next if (! $date_found);
            @fields = split(/,/, $line);
            ($m, $d, $y, $h, $mi) = &parse_date($fields[1], 0);
            if ($subdaily) {
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            } else {
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            }
            $val = $fields[$value_field];
            if (defined($val) && $val ne "") {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl % 250 == 0) {
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "Dataquery format") {
        $line = <$fh>;
        if ($line !~ /^Date Time,/) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        chomp $line;
        @fields = split(/,/, $line);
        $value_field = &list_match($parm, @fields);
        if ($value_field == -1) {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        while (defined($line = <$fh>)) {
            chomp $line;
            ($date_found, $date_only) = &found_date($line);
            next if (! $date_found);
            @fields = split(/,/, $line);
            if ($date_only) {
                ($m, $d, $y) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $val = $fields[$value_field];
            if (defined($val) && $val ne "" && $val !~ /na/i && $val != -99 && $val != -999) {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl % 250 == 0) {
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "USGS Water Services format") {
        $line = <$fh>;
        if ($line !~ /^\# ---------------------------------- WARNING ----------/) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        $daily = $tscode = -999;
        while (defined($line = <$fh>)) {
            chomp $line;
            if ($line =~ /^\#\s+TS_ID\s+Parameter\s+.*Description/) {
                $pos   = index($line, "Description");
                $daily = ($line =~ /Parameter\s+Statistic/) ? 1 : 0;
                $line  = <$fh>;
                chomp $line;
                if ($parm ne substr($line,$pos)) {
                    return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
                }
                $line =~ s/^\#\s+//;
                if ($daily) {
                    ($ts_id, $pcode, $stat, @fields) = split(/\s+/, $line);
                    $tscode = $ts_id . "_" . $pcode . "_" . $stat;
                } else {
                    ($ts_id, $pcode, @fields) = split(/\s+/, $line);
                    $tscode = $ts_id . "_" . $pcode;
                }
                next;
            }
            next if ($line =~ /^\#/);
            if ($line =~ /^agency_cd\tsite_no\tdatetime\t/) {
                @fields = split(/\t/, $line);
                $value_field = &list_match($tscode, @fields);
                if ($value_field == -1) {
                    return &pop_up_error($parent, "Parameter header mismatch ($tscode):\n$file");
                }
                $line = <$fh>;
                last;
            }
        }
        if ($daily eq "-999" || $tscode eq "-999") {
            return &pop_up_error($parent, "Metadata mismatch on parameter info ($parm):\n$file");
        }
        while (defined($line = <$fh>)) {
            chomp $line;
            @fields = split(/\t/, $line);
            ($date_found, $date_only) = &found_date($fields[2]);
            next if (! $date_found);
            if ($date_only) {
                ($m, $d, $y) = &parse_date($fields[2], $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($fields[2], $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $val = $fields[$value_field];
            if (defined($val) && $val ne "") {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl % 250 == 0) {
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "USGS Data Grapher format") {
        $line = <$fh>;
        chomp $line;
        if ($line !~ /Data from U.S. Geological Survey \(USGS\)\.$/) {
            return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
        }
        $lines_left = 100;    # limit search to the first 100 lines
        while ($lines_left > 0 && defined($line = <$fh>)) {
            chomp $line;
            $lines_left--;
            if ($line =~ /Parameters:$/) {
                while ($lines_left > 0 && defined($line = <$fh>)) {
                    $lines_left--;
                    chomp $line;
                    $line =~ s/^\#//;
                    $line =~ s/^\s+//;
                    last if ($line eq "");
                    $line =~ s/ -- from .$//;
                    push (@parms, $line);
                }
                last;
            }
        }
        $value_field = &list_match($parm, @parms) +1;
        if ($value_field < 1) {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        while (defined($line = <$fh>)) {
            chomp $line;
            $line =~ s/^\#//;
            $line =~ s/^\s+//;
            next if ($line eq "");
            @fields = split(/\t|,/, $line);
            ($date_found, $date_only) = &found_date($fields[0]);
            next if (! $date_found);
            if ($date_only) {
                ($m, $d, $y) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $val = $fields[$value_field];
            if (defined($val) && $val ne "" && $val ne "-123456E20") {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl % 250 == 0) {
                &update_progress_bar($pbar, $nl);
            }
        }

    } elsif ($file_type eq "CSV format") {
        if ($parm =~ /^Parameter\d+$/) {
            ($value_field = $parm) =~ s/^Parameter(\d+)$/$1/;
        } else {
            $lines_left = 50;    # look at only the first 50 lines
            while ($lines_left > 0 && defined($line = <$fh>)) {
                $lines_left--;
                next if ($line =~ /^\#/);
                chomp $line;
                $line =~ s/,+$//;
                @fields = split(/,/, $line);
                if ($#fields >= 1 && ($fields[0] eq "DateTime" || $fields[0] eq "Date"
                                                               || $fields[0] eq "Date/Time")) {
                    $value_field = &list_match($parm, @fields);
                    last;
                }
            }
        }
        if ($value_field < 1) {
            return &pop_up_error($parent, "Parameter mismatch ($parm):\n$file");
        }
        while (defined($line = <$fh>)) {
            next if ($line =~ /^\#/);
            chomp $line;
            ($date_found, $date_only) = &found_date($line);
            next if (! $date_found);
            @fields = split(/,/, $line);
            if ($date_only) {
                ($m, $d, $y) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d", $y, $m, $d);
            } else {
                ($m, $d, $y, $h, $mi) = &parse_date($fields[0], $date_only);
                $dt = sprintf("%04d%02d%02d%02d%02d", $y, $m, $d, $h, $mi);
            }
            $val = $fields[$value_field];
            if (defined($val) && $val ne "" && $val !~ /na/i && $val != -99 && $val != -999) {
                $ts_data{$dt} = $val;
            } else {
                $ts_data{$dt} = $missing;
            }

            $nl++;
            if ($progress_bar && $nl % 250 == 0) {
                &update_progress_bar($pbar, $nl);
            }
        }

    } else {
        return &pop_up_error($parent, "Incorrect file type ($file_type):\n$file");
    }

#   Close the data file
    close ($fh)
        or &pop_up_info($parent, "Unable to close time-series data file:\n$file");

    return %ts_data;
}


############################################################################
#
# Subroutine to convert the values in a time series to new units.
#
sub convert_timeseries {
    my ($parent, $ctype, $array, %ts_data) = @_;
    my ($add, $dt, $i, $mult);

#   Identify the conversion
    if ((&list_match($ctype, @conv_types) == -1 && lc($ctype) !~ /^custom,/) || lc($ctype) eq "none") {
        return %ts_data;
    } elsif ($ctype eq "degC to degF") {
        $mult =  1.8;
        $add  = 32.0;
    } elsif ($ctype eq "degF to degC") {
        $mult =   5./9.;
        $add  = (-5./9.)*32.;
    } elsif ($ctype eq "m to ft") {
        $mult = 3.28084;
        $add  = 0.0;
    } elsif ($ctype eq "ft to m") {
        $mult = 1./3.28084;
        $add  = 0.0;
    } elsif ($ctype eq "cms to cfs") {
        $mult = 35.31467;
        $add  = 0.0;
    } elsif ($ctype eq "cfs to cms") {
        $mult = 1./35.31467;
        $add  = 0.0;
    } elsif ($ctype eq "cfs to kcfs") {
        $mult = 0.001;
        $add  = 0.0;
    } elsif ($ctype eq "mg/L to ug/L") {
        $mult = 1000.;
        $add  = 0.0;
    } elsif ($ctype eq "ug/L to mg/L") {
        $mult = 1./1000.;
        $add  = 0.0;
    } elsif ($ctype eq "days to hours") {
        $mult = 24.;
        $add  = 0.0;
    } elsif ($ctype eq "hours to days") {
        $mult = 1./24.;
        $add  = 0.0;
    } elsif (lc($ctype) =~ /^custom,/) {
        $ctype =~ s/^custom,//i;
        ($mult, $add) = split(/,/, $ctype);
        if (! defined($mult) || $mult eq "" || ! defined($add) || $add eq "") {
            return &pop_up_error($parent, "Custom conversion factors not defined.");
        }
    }

#   Implement the conversion
    foreach $dt (keys %ts_data) {
        if ($array) {
            for ($i=0; $i<=$#{ $ts_data{$dt} }; $i++) {
                next if ($ts_data{$dt}[$i] eq "na");
                $ts_data{$dt}[$i] *= $mult;
                $ts_data{$dt}[$i] += $add;
            }
        } elsif ($ts_data{$dt} ne "na") {
            $ts_data{$dt} *= $mult;
            $ts_data{$dt} += $add;
        }
    }
    return %ts_data;
}


############################################################################
#
# Subroutine to convert the values in a slice time series to new units.
#
# The data hash has a date/time (dt) index and includes information on the
# surface-layer index, the current upstream segment of each branch, and
# the parameter value array.  The object id is passed so that the W2 grid
# information can be accessed.  The waterbody index is needed for slice
# data from contour output files, whereas "all" indicates all waterbodies
# for a vector output file.
#
sub convert_slice_data {
    my ($parent, $ctype, $id, $jw, %data) = @_;
    my ($add, $dt, $i, $jb, $jjw, $k, $kmx, $kt, $mult, $nwb,
        @be, @bs, @cus, @ds, @pdata, @us,
       );

#   Identify the conversion
    if ((&list_match($ctype, @conv_types) == -1 && lc($ctype) !~ /^custom,/) || lc($ctype) eq "none") {
        return %data;
    } elsif ($ctype eq "degC to degF") {
        $mult =  1.8;
        $add  = 32.0;
    } elsif ($ctype eq "degF to degC") {
        $mult =   5./9.;
        $add  = (-5./9.)*32.;
    } elsif ($ctype eq "m to ft") {
        $mult = 3.28084;
        $add  = 0.0;
    } elsif ($ctype eq "ft to m") {
        $mult = 1./3.28084;
        $add  = 0.0;
    } elsif ($ctype eq "cms to cfs") {
        $mult = 35.31467;
        $add  = 0.0;
    } elsif ($ctype eq "cfs to cms") {
        $mult = 1./35.31467;
        $add  = 0.0;
    } elsif ($ctype eq "cfs to kcfs") {
        $mult = 0.001;
        $add  = 0.0;
    } elsif ($ctype eq "mg/L to ug/L") {
        $mult = 1000.;
        $add  = 0.0;
    } elsif ($ctype eq "ug/L to mg/L") {
        $mult = 1./1000.;
        $add  = 0.0;
    } elsif ($ctype eq "days to hours") {
        $mult = 24.;
        $add  = 0.0;
    } elsif ($ctype eq "hours to days") {
        $mult = 1./24.;
        $add  = 0.0;
    } elsif (lc($ctype) =~ /^custom,/) {
        $ctype =~ s/^custom,//i;
        ($mult, $add) = split(/,/, $ctype);
        if (! defined($mult) || $mult eq "" || ! defined($add) || $add eq "") {
            return &pop_up_error($parent, "Custom conversion factors not defined.");
        }
    }

#   Implement the conversion
    @bs  = @{ $grid{$id}{bs} };
    @be  = @{ $grid{$id}{be} };
    @us  = @{ $grid{$id}{us} };
    @ds  = @{ $grid{$id}{ds} };
    $kmx = $grid{$id}{kmx};
    $nwb = $grid{$id}{nwb};

    foreach $dt (keys %data) {
        @cus   = @{ $data{$dt}{cus} };
        @pdata = @{ $data{$dt}{parm_data} };
        for ($jjw=1; $jjw<=$nwb; $jjw++) {                        # loop over waterbodies
            if ($jw eq "all") {
                $kt = $data{$dt}{kt}[$jjw];                       # vector file has kt array
            } else {
                next if ($jw != $jjw);
                $kt = $data{$dt}{kt};                             # contour file
            }
            for ($jb=$bs[$jjw]; $jb<=$be[$jjw]; $jb++) {          # loop over branches
                next if (! defined($cus[$jb]) || $cus[$jb] == 0); # skip inactive branches
                for ($i=$cus[$jb]; $i<=$ds[$jb]; $i++) {          # loop through segments
                    for ($k=$kt; $k<=$kmx; $k++) {                # loop over layers
                        last if (! defined($pdata[$k][$i]));      # cannot count on kb for sloped grid
                        last if ($pdata[$k][$i] == -99);          # vector file flag for inactive cell
                        $pdata[$k][$i] *= $mult;
                        $pdata[$k][$i] += $add;
                    }
                }
            }
        }
        $data{$dt}{parm_data} = [ @pdata ];
    }
    return %data;
}


############################################################################
#
# Subroutine to convert the values in a time/distance map dataset to new units.
# The data hash has a date/time (dt) hash key and a segment (seg) hash key.
#
sub convert_tdmap_data {
    my ($parent, $ctype, %data) = @_;
    my ($add, $dt, $mult, $seg);

#   Identify the conversion
    if ((&list_match($ctype, @conv_types) == -1 && lc($ctype) !~ /^custom,/) || lc($ctype) eq "none") {
        return %data;
    } elsif ($ctype eq "degC to degF") {
        $mult =  1.8;
        $add  = 32.0;
    } elsif ($ctype eq "degF to degC") {
        $mult =   5./9.;
        $add  = (-5./9.)*32.;
    } elsif ($ctype eq "m to ft") {
        $mult = 3.28084;
        $add  = 0.0;
    } elsif ($ctype eq "ft to m") {
        $mult = 1./3.28084;
        $add  = 0.0;
    } elsif ($ctype eq "cms to cfs") {
        $mult = 35.31467;
        $add  = 0.0;
    } elsif ($ctype eq "cfs to cms") {
        $mult = 1./35.31467;
        $add  = 0.0;
    } elsif ($ctype eq "cfs to kcfs") {
        $mult = 0.001;
        $add  = 0.0;
    } elsif ($ctype eq "mg/L to ug/L") {
        $mult = 1000.;
        $add  = 0.0;
    } elsif ($ctype eq "ug/L to mg/L") {
        $mult = 1./1000.;
        $add  = 0.0;
    } elsif ($ctype eq "days to hours") {
        $mult = 24.;
        $add  = 0.0;
    } elsif ($ctype eq "hours to days") {
        $mult = 1./24.;
        $add  = 0.0;
    } elsif (lc($ctype) =~ /^custom,/) {
        $ctype =~ s/^custom,//i;
        ($mult, $add) = split(/,/, $ctype);
        if (! defined($mult) || $mult eq "" || ! defined($add) || $add eq "") {
            return &pop_up_error($parent, "Custom conversion factors not defined.");
        }
    }

#   Implement the conversion
    foreach $dt (keys %data) {                      # each date/time
        foreach $seg (keys %{ $data{$dt} }) {       # each segment
            next if ($data{$dt}{$seg} == -99);      # inactive segment
            $data{$dt}{$seg} *= $mult;
            $data{$dt}{$seg} += $add;
        }
    }
    return %data;
}


############################################################################
#
# Compute a vertical profile stat or subsample and reformat the input data
# into a single hash with a date/time key and a segment key.
# For now, this routine assumes a stacked-rectangle cross-section.
#
sub compute_pstat_from_slice {
    my ($parent, $id, $pstat, $jw, $pbar, %data) = @_;
    my ($dt, $i, $jb, $jjw, $k, $kmx, $kt, $nd, $nwb, $sum, $xarea,
        @b, @be, @bs, @cus, @ds, @dts, @el, @elws, @h, @kb, @pdata, @us,
        %tdm_data,
       );

    $nd = 0;
    %tdm_data = ();

#   Return if the profile stat is unacceptable
    if ($pstat !~ /(Surface value|Volume-weighted)/i) {
        return &pop_up_error($parent, "Unacceptable value for profile stat: $pstat");
    }

#   Obtain some grid information
    @bs  = @{ $grid{$id}{bs} };
    @be  = @{ $grid{$id}{be} };
    @us  = @{ $grid{$id}{us} };
    @ds  = @{ $grid{$id}{ds} };
    @b   = @{ $grid{$id}{b}  };
    @h   = @{ $grid{$id}{h}  };
    @el  = @{ $grid{$id}{el} };
    @kb  = @{ $grid{$id}{kb} };
    $kmx = $grid{$id}{kmx};
    $nwb = $grid{$id}{nwb};

#   Loop over the available data
    @dts = sort numerically keys %data;
    &reset_progress_bar($pbar, $#dts +1, "Computing profile stats... Date = 1");
    foreach $dt (@dts) {
        @cus   = @{ $data{$dt}{cus} };
        @elws  = @{ $data{$dt}{elws} };
        @pdata = @{ $data{$dt}{parm_data} };
        for ($jjw=1; $jjw<=$nwb; $jjw++) {                          # loop over waterbodies
            if ($jw eq "all") {
                $kt = $data{$dt}{kt}[$jjw];                         # vector file has kt array
            } else {
                next if ($jw != $jjw);
                $kt = $data{$dt}{kt};                               # contour file
            }
            for ($jb=$bs[$jjw]; $jb<=$be[$jjw]; $jb++) {            # loop over branches
                if (! defined($cus[$jb]) || $cus[$jb] == 0) {       # inactive branches
                    for ($i=$us[$jb]; $i<=$ds[$jb]; $i++) {
                        $tdm_data{$dt}{$i} = -99;
                    }
                    next;
                }
                for ($i=$us[$jb]; $i<=$ds[$jb]; $i++) {             # loop through segments
                    if ($i < $cus[$jb]) {                           # inactive segments
                        $tdm_data{$dt}{$i} = -99;
                    } elsif ($pstat eq "Surface value") {           # surface value
                        $tdm_data{$dt}{$i} = $pdata[$kt][$i];
                    } elsif ($pstat eq "Volume-weighted") {         # volume weighted
                        $xarea = 0.0;                               # stacked rectangles
                        for ($k=1; $k<=$kt; $k++) {
                            next if ($el[$k+1][$i] >= $elws[$i]);
                            if ($elws[$i] <= $el[$k][$i]) {
                                $xarea = &max(0.000001,$b[$k][$i]) *($elws[$i] -$el[$k+1][$i]);
                            } else {
                                $xarea += &max(0.000001,$b[$k][$i]) *$h[$k][$jjw];
                            }
                        }
                        $sum = $xarea *$pdata[$kt][$i];
                        for ($k=$kt+1; $k<=$kb[$i]; $k++) {
                            $xarea += $b[$k][$i] *$h[$k][$jjw];
                            $sum   += $b[$k][$i] *$h[$k][$jjw] * $pdata[$k][$i];
                        }
                        $tdm_data{$dt}{$i} = ($xarea > 0.0) ? $sum /$xarea : -99;
                    }
                }
            }
        }
        $nd++;
        &update_progress_bar($pbar, $nd, $dt);
    }
    return %tdm_data;
}


############################################################################
#
# Compute goodness-of-fit statistics for one-dimensional hashes that have a
# datetime as their key.
#
# Requires a reference dataset and a dataset to be tested for goodness-of-fit.
# Also requires a date/time tolerance for finding a comparison date/time in
# the reference dataset.  Default is 10 minutes.
#
# Computes the following:
#   ME   mean error
#   MAE  mean absolute error
#   RMSE root mean squared error
# for the entire time period and possibly by month as well.
#
sub get_ts_stats {
    my ($data_ref, $refdata_ref, $monthly, $tol) = @_;
    my (
        $data_daily, $diff, $dt, $dt_ref, $dt_ref2, $found, $m, $mi, $mon,
        $n_tot, $ref_daily, $sum_absdiff, $sum_diff, $sum_sqdiff,

        @keys_data, @keys_ref, @mon_absdiff, @mon_diff, @mon_sqdiff, @n_mon,

        %data, %ref, %stats,
       );

    $monthly =  0 if (! defined($monthly) || $monthly ne "1");
    $tol     = 10 if (! defined($tol)     || $tol eq "");
    $tol     =  0 if ($tol < 0);

    %data  = %{ $data_ref    };
    %ref   = %{ $refdata_ref };
    %stats = ();

#   Get hash keys and determine whether the keys are daily or subdaily
    @keys_data  = sort keys %data;
    @keys_ref   = keys %ref;
    $data_daily = (length($keys_data[0]) == 12) ? 0 : 1;
    $ref_daily  = (length($keys_ref[0])  == 12) ? 0 : 1;

    $n_tot = $sum_diff = $sum_absdiff = $sum_sqdiff = 0;
    @n_mon = @mon_diff = @mon_absdiff = @mon_sqdiff = ();
    @n_mon       = (0) x 12;
    @mon_diff    = (0) x 12;
    @mon_absdiff = (0) x 12;
    @mon_sqdiff  = (0) x 12;

    foreach $dt (@keys_data) {
        next if ($data{$dt} eq "na");
        $dt_ref = $dt;
        if ($data_daily != $ref_daily) {
            if ($ref_daily) {
                $dt_ref = &nearest_daily_dt($dt);
                next if (&get_dt_diff($dt, 10000 *$dt_ref) > $tol || ! defined($ref{$dt_ref}));
            } else {
                $dt_ref .= "0000";
            }
        }
        if (! defined($ref{$dt_ref})) {
            next if (($data_daily && $ref_daily) || $tol == 0);
            $found = 0;
            for ($mi=1; $mi<=$tol; $mi++) {
                $dt_ref2 = &adjust_dt($dt_ref, $mi);
                if (defined($ref{$dt_ref2})){
                    $dt_ref = $dt_ref2;
                    $found  = 1;
                    last;
                }
                $dt_ref2 = &adjust_dt($dt_ref, -1 *$mi);
                if (defined($ref{$dt_ref2})){
                    $dt_ref = $dt_ref2;
                    $found  = 1;
                    last;
                }
            }
            next if (! $found);
        }
        next if ($ref{$dt_ref} eq "na");
        $n_tot++;
        $diff         = $data{$dt} -$ref{$dt_ref};
        $sum_diff    += $diff;
        $sum_absdiff += abs($diff);
        $sum_sqdiff  += $diff *$diff;
        if ($monthly) {
            $m = substr($dt,4,2) -1;
            $n_mon[$m]++;
            $mon_diff[$m]    += $diff;
            $mon_absdiff[$m] += abs($diff);
            $mon_sqdiff[$m]  += $diff *$diff;
        }
    }

#   Compute and return the final stats
    $stats{n}{all} = $n_tot;
    if ($n_tot == 0) {
        $stats{me}{all}   = "na";
        $stats{mae}{all}  = "na";
        $stats{rmse}{all} = "na";
    } else {
        $stats{me}{all}   = $sum_diff    /$n_tot;
        $stats{mae}{all}  = $sum_absdiff /$n_tot;
        $stats{rmse}{all} = sqrt($sum_sqdiff /$n_tot);
    }
    if ($monthly) {
        for ($m=0; $m<12; $m++) {
            $mon = $mon_names[$m];
            if ($n_mon[$m] == 0) {
                $stats{me}{$mon}   = "na";
                $stats{mae}{$mon}  = "na";
                $stats{rmse}{$mon} = "na";
            } else {
                $stats{me}{$mon}   = $mon_diff[$m]    /$n_mon[$m];
                $stats{mae}{$mon}  = $mon_absdiff[$m] /$n_mon[$m];
                $stats{rmse}{$mon} = sqrt($mon_sqdiff[$m] /$n_mon[$m]);
            }
            $stats{n}{$mon} = $n_mon[$m];
        }
    }
    return %stats;
}


############################################################################
#
# Compute goodness-of-fit statistics for a comparison of W2 model profiles
# against measured vertical profiles.  Also computes goodness-of-fit for
# the water-surface elevation.  These fit statistics are in program units,
# meaning Celsius for temperature and meters for water-surface elevations.
#
# If the measured profile data are provided as depths, then the comparisons
# to model results are in terms of depths.  If the measured profile data
# are from fixed elevations, then the comparisons to model results are in
# terms of elevations.
#
# Requires W2 profile results and separate measured vertical profiles.
# Also requires a date/time tolerance for finding a comparison date/time in
# the reference dataset.  Default is 10 minutes.
#
# Modeled profiles may be interpolated vertically to match measured depths
# or elevations, at the user's preference.
#
# Computes the following:
#   ME   mean error
#   MAE  mean absolute error
#   RMSE root mean squared error
# for the entire time period and also possibly by month.
#
# Any measured data marked as estimates will be excluded from the analysis.
#
sub get_stats_ref_profile {
    my ($id, $seg, $monthly, $tol, $interp, $eldata_ref, $pdata_ref, $ref_pro_ref) = @_;
    my (
        $data_daily, $diff, $dist, $dt, $dt_ref, $dt_ref2, $found,
        $got_depth, $i, $lastpt, $lower, $m, $mi, $mid, $mon, $n, $npro,
        $n_tot, $n_tot2, $pdat, $ref_daily, $sum_absdiff, $sum_absdiff2,
        $sum_diff, $sum_diff2, $sum_mae, $sum_me, $sum_rmse, $sum_sqdiff,
        $sum_sqdiff2, $upper, $w2_layers,

        @depths, @el, @elevations, @estimated, @kb, @keys_data, @keys_ref,
        @mon_absdiff, @mon_diff, @mon_mae, @mon_me, @mon_rmse, @mon_sqdiff,
        @n_mon, @npro_mon, @ref_pdata, @valid_eldep, @valid_pdata, @w2_pro,

        %elev_data, %parm_data, %ref_data, %ref_profile, %ref_wsurf,
        %estats, %pstats, %pstats2,
       );

    $interp  =  0 if (! defined($interp)  || $interp  ne "1");
    $monthly =  0 if (! defined($monthly) || $monthly ne "1");
    $tol     = 10 if (! defined($tol)     || $tol eq "");
    $tol     =  0 if ($tol < 0);
    %estats  = %pstats = %pstats2 = ();

#   Get grid information
    @el = @{ $grid{$id}{el} };
    @kb = @{ $grid{$id}{kb} };

#   Get W2 profile data
    %elev_data = %{ $eldata_ref };
    %parm_data = %{ $pdata_ref  };

#   Get reference profile data
    %ref_profile = %{ $ref_pro_ref            };
    %ref_data    = %{ $ref_profile{pdata}     };
    %ref_wsurf   = %{ $ref_profile{ws_elev}   };
    @estimated   = @{ $ref_profile{estimated} };
    $got_depth   = ($ref_profile{elv_dep} eq "elevation") ? 0 : 1;
    if ($got_depth) {
        @depths     = @{ $ref_profile{depths} };
    } else {
        @elevations = @{ $ref_profile{elevations} };
    }
    $lastpt = ($got_depth) ? $#depths : $#elevations;

#   Get hash keys and determine whether the keys are daily or subdaily
    @keys_data  = sort keys %parm_data;
    @keys_ref   = keys %ref_data;
    $data_daily = (length($keys_data[0]) == 12) ? 0 : 1;
    $ref_daily  = (length($keys_ref[0])  == 12) ? 0 : 1;

    $n_tot = $sum_diff = $sum_absdiff = $sum_sqdiff = 0;
    @n_mon = @mon_diff = @mon_absdiff = @mon_sqdiff = ();
    @n_mon       = (0) x 12;
    @mon_diff    = (0) x 12;
    @mon_absdiff = (0) x 12;
    @mon_sqdiff  = (0) x 12;
    $npro     = $sum_me = $sum_mae = $sum_rmse = 0;
    @npro_mon = @mon_me = @mon_mae = @mon_rmse = ();
    @npro_mon = (0) x 12;
    @mon_me   = (0) x 12;
    @mon_mae  = (0) x 12;
    @mon_rmse = (0) x 12;

#   First work on stats for the parameter values.
#   Loop over the W2 profile dates and find matches in the reference data
    foreach $dt (@keys_data) {
        next if (! defined($elev_data{$dt}) || ! defined($parm_data{$dt}));
        $dt_ref = $dt;
        if ($data_daily != $ref_daily) {
            if ($ref_daily) {
                $dt_ref = &nearest_daily_dt($dt);
                next if (&get_dt_diff($dt, 10000 *$dt_ref) > $tol || ! defined($ref_data{$dt_ref}));
            } else {
                $dt_ref .= "0000";
            }
        }
        if (! defined($ref_data{$dt_ref})) {
            next if (($data_daily && $ref_daily) || $tol == 0);
            $found = 0;
            for ($mi=1; $mi<=$tol; $mi++) {
                $dt_ref2 = &adjust_dt($dt_ref, $mi);
                if (defined($ref_data{$dt_ref2})){
                    $dt_ref = $dt_ref2;
                    $found  = 1;
                    last;
                }
                $dt_ref2 = &adjust_dt($dt_ref, -1 *$mi);
                if (defined($ref_data{$dt_ref2})){
                    $dt_ref = $dt_ref2;
                    $found  = 1;
                    last;
                }
            }
            next if (! $found);
        }

#       Compute model and data elevations and skip any na values
        $w2_layers   = $#{ $parm_data{$dt} } +1;
        @w2_pro      = @{ $parm_data{$dt} };
        @ref_pdata   = @{ $ref_data{$dt_ref} };
        @valid_pdata = ();
        @valid_eldep = ();
        for ($i=0; $i<=$lastpt; $i++) {
            next if ($ref_pdata[$i] eq "na");
            next if ($estimated[$i]);
            if ($got_depth) {
                push (@valid_eldep, $depths[$i]);
            } else {
                if ($ref_wsurf{$dt_ref} ne "na") {
                    next if ($elevations[$i] > $ref_wsurf{$dt_ref} +0.1/3.28084);
                } else {
                    next if ($elevations[$i] > $elev_data{$dt} +0.1/3.28084);
                }
                push (@valid_eldep, $elevations[$i]);
            }
            push (@valid_pdata, $ref_pdata[$i]);
        }

#       Find elevation or depth matches and compute model/data differences
        $n_tot2 = $sum_diff2 = $sum_absdiff2 = $sum_sqdiff2 = 0;
        for ($n=0; $n<=$#valid_pdata; $n++) {
            for ($i=0; $i<$w2_layers; $i++) {
                if ($i == 0) {
                    $upper = $elev_data{$dt} +0.1/3.28084;
                } else {
                    $upper = $el[$kb[$seg] -$w2_layers +1 +$i][$seg];
                }
                $lower = $el[$kb[$seg] -$w2_layers +2 +$i][$seg];
                if ($got_depth) {
                    $upper = $elev_data{$dt} -$upper;
                    $lower = $elev_data{$dt} -$lower;
                }
                if (($got_depth && $valid_eldep[$n] >= $upper && $valid_eldep[$n] < $lower)
                      || (! $got_depth && $valid_eldep[$n] <= $upper && $valid_eldep[$n] > $lower)) {
                    $n_tot++;
                    $n_tot2++;
                    if ($interp && $w2_layers > 1) {
                        $mid = 0.5*($upper +$lower);

#                       Vertical interpolation of model profile using depths
                        if ($got_depth) {
                            if (($i == 0            && $valid_eldep[$n] <= $mid) ||
                                ($i == $w2_layers-1 && $valid_eldep[$n] >= $mid)) {
                                $pdat = $w2_pro[$i];
                            } elsif ($valid_eldep[$n] <= $mid) {
                                if ($i == 1) {
                                    $dist = 0.5*($elev_data{$dt} -$el[$kb[$seg] -$w2_layers +2][$seg])
                                            +0.5*($lower -$upper);
                                } else {
                                    $dist = 0.5*($el[$kb[$seg] -$w2_layers    +$i][$seg]
                                                -$el[$kb[$seg] -$w2_layers +1 +$i][$seg])
                                            +0.5*($lower -$upper);
                                }
                                $pdat = $w2_pro[$i] +($w2_pro[$i-1]-$w2_pro[$i])
                                                     *($mid-$valid_eldep[$n])/$dist;
                            } else {
                                $dist = 0.5*($el[$kb[$seg] -$w2_layers +2 +$i][$seg]
                                            -$el[$kb[$seg] -$w2_layers +3 +$i][$seg])
                                        +0.5*($lower -$upper);
                                $pdat = $w2_pro[$i] +($w2_pro[$i+1]-$w2_pro[$i])
                                                     *($valid_eldep[$n]-$mid)/$dist;
                            }

#                       Vertical interpolation of model profile using elevations
                        } else {
                            if (($i == 0            && $valid_eldep[$n] >= $mid) ||
                                ($i == $w2_layers-1 && $valid_eldep[$n] <= $mid)) {
                                $pdat = $w2_pro[$i];
                            } elsif ($valid_eldep[$n] >= $mid) {
                                if ($i == 1) {
                                    $dist = 0.5*($elev_data{$dt} -$el[$kb[$seg] -$w2_layers +2][$seg])
                                            +0.5*($upper -$lower);
                                } else {
                                    $dist = 0.5*($el[$kb[$seg] -$w2_layers    +$i][$seg]
                                                -$el[$kb[$seg] -$w2_layers +1 +$i][$seg])
                                            +0.5*($upper -$lower);
                                }
                                $pdat = $w2_pro[$i] +($w2_pro[$i-1]-$w2_pro[$i])
                                                     *($valid_eldep[$n]-$mid)/$dist;
                            } else {
                                $dist = 0.5*($el[$kb[$seg] -$w2_layers +2 +$i][$seg]
                                            -$el[$kb[$seg] -$w2_layers +3 +$i][$seg])
                                        +0.5*($upper -$lower);
                                $pdat = $w2_pro[$i] +($w2_pro[$i+1]-$w2_pro[$i])
                                                     *($mid-$valid_eldep[$n])/$dist;
                            }
                        }
                        $diff = $pdat -$valid_pdata[$n];

#                   Or, no vertical interpolation. Match is somewhere in vertical range of model cell.
                    } else {
                        $diff = $w2_pro[$i] -$valid_pdata[$n];
                    }
                    $sum_diff     += $diff;
                    $sum_diff2    += $diff;
                    $sum_absdiff  += abs($diff);
                    $sum_absdiff2 += abs($diff);
                    $sum_sqdiff   += $diff *$diff;
                    $sum_sqdiff2  += $diff *$diff;
                    if ($monthly) {
                        $m = substr($dt,4,2) -1;
                        $n_mon[$m]++;
                        $mon_diff[$m]    += $diff;
                        $mon_absdiff[$m] += abs($diff);
                        $mon_sqdiff[$m]  += $diff *$diff;
                    }
                    last;
                }
            }
        }

#       Add to the stat sums tracked by profile
        if ($n_tot2 > 0) {
            $npro++;
            $sum_me   += $sum_diff2    /$n_tot2;      # running sum of ME values, by profile
            $sum_mae  += $sum_absdiff2 /$n_tot2;      # running sum of MAE values, by profile
            $sum_rmse += sqrt($sum_sqdiff2 /$n_tot2); # running sum of RMSE values, by profile
            if ($monthly) {
                $m = substr($dt,4,2) -1;
                $npro_mon[$m]++;
                $mon_me[$m]   += $sum_diff2    /$n_tot2;      # running sum of ME, by profile, by month
                $mon_mae[$m]  += $sum_absdiff2 /$n_tot2;      # running sum of MAE, by profile, by month
                $mon_rmse[$m] += sqrt($sum_sqdiff2 /$n_tot2); # running sum of RMSE, by profile, by month
            }
        }
    }

#   Compute the final parameter stats, using all point comparisons weighted equally
    $pstats{n}{all} = $n_tot;
    if ($n_tot == 0) {
        $pstats{me}{all}   = "na";
        $pstats{mae}{all}  = "na";
        $pstats{rmse}{all} = "na";
    } else {
        $pstats{me}{all}   = $sum_diff    /$n_tot;
        $pstats{mae}{all}  = $sum_absdiff /$n_tot;
        $pstats{rmse}{all} = sqrt($sum_sqdiff /$n_tot);
    }
    if ($monthly) {
        for ($m=0; $m<12; $m++) {
            $mon = $mon_names[$m];
            if ($n_mon[$m] == 0) {
                $pstats{me}{$mon}   = "na";
                $pstats{mae}{$mon}  = "na";
                $pstats{rmse}{$mon} = "na";
            } else {
                $pstats{me}{$mon}   = $mon_diff[$m]    /$n_mon[$m];
                $pstats{mae}{$mon}  = $mon_absdiff[$m] /$n_mon[$m];
                $pstats{rmse}{$mon} = sqrt($mon_sqdiff[$m] /$n_mon[$m]);
            }
            $pstats{n}{$mon} = $n_mon[$m];
        }
    }

#   Compute the final mean stats, by profile
    $pstats2{n}{all} = $npro;
    if ($npro == 0) {
        $pstats2{me}{all}   = "na";
        $pstats2{mae}{all}  = "na";
        $pstats2{rmse}{all} = "na";
    } else {
        $pstats2{me}{all}   = $sum_me   /$npro;  # average ME, by profile
        $pstats2{mae}{all}  = $sum_mae  /$npro;  # average MAE, by profile
        $pstats2{rmse}{all} = $sum_rmse /$npro;  # average RMSE, by profile
    }
    if ($monthly) {
        for ($m=0; $m<12; $m++) {
            $mon = $mon_names[$m];
            if ($npro_mon[$m] == 0) {
                $pstats2{me}{$mon}   = "na";
                $pstats2{mae}{$mon}  = "na";
                $pstats2{rmse}{$mon} = "na";
            } else {
                $pstats2{me}{$mon}   = $mon_me[$m]   /$npro_mon[$m];  # avg ME, by profile, by month
                $pstats2{mae}{$mon}  = $mon_mae[$m]  /$npro_mon[$m];  # avg MAE, by profile, by month
                $pstats2{rmse}{$mon} = $mon_rmse[$m] /$npro_mon[$m];  # avg RMSE, by profile, by month
            }
            $pstats2{n}{$mon} = $npro_mon[$m];
        }
    }

#   Reset variables to work on stats for water-surface elevations
    $n_tot = $sum_diff = $sum_absdiff = $sum_sqdiff = 0;
    @n_mon = @mon_diff = @mon_absdiff = @mon_sqdiff = ();
    @n_mon       = (0) x 12;
    @mon_diff    = (0) x 12;
    @mon_absdiff = (0) x 12;
    @mon_sqdiff  = (0) x 12;

#   Loop over the W2 profile dates and find matches in the reference data
    foreach $dt (@keys_data) {
        next if (! defined($elev_data{$dt}));
        $dt_ref = $dt;
        if ($data_daily != $ref_daily) {
            if ($ref_daily) {
                $dt_ref = &nearest_daily_dt($dt);
                next if (&get_dt_diff($dt, 10000 *$dt_ref) > $tol || ! defined($ref_wsurf{$dt_ref}));
            } else {
                $dt_ref .= "0000";
            }
        }
        if (! defined($ref_wsurf{$dt_ref})) {
            next if (($data_daily && $ref_daily) || $tol == 0);
            $found = 0;
            for ($mi=1; $mi<=$tol; $mi++) {
                $dt_ref2 = &adjust_dt($dt_ref, $mi);
                if (defined($ref_wsurf{$dt_ref2})){
                    $dt_ref = $dt_ref2;
                    $found  = 1;
                    last;
                }
                $dt_ref2 = &adjust_dt($dt_ref, -1 *$mi);
                if (defined($ref_wsurf{$dt_ref2})){
                    $dt_ref = $dt_ref2;
                    $found  = 1;
                    last;
                }
            }
            next if (! $found);
        }

#       Compute model and data elevations and skip any na values
        next if ($ref_wsurf{$dt_ref} eq "na");
        $n_tot++;
        $diff         = $elev_data{$dt} -$ref_wsurf{$dt_ref};
        $sum_diff    += $diff;
        $sum_absdiff += abs($diff);
        $sum_sqdiff  += $diff *$diff;
        if ($monthly) {
            $m = substr($dt,4,2) -1;
            $n_mon[$m]++;
            $mon_diff[$m]    += $diff;
            $mon_absdiff[$m] += abs($diff);
            $mon_sqdiff[$m]  += $diff *$diff;
        }
    }

#   Compute the final water-surface elevation stats
    $estats{n}{all} = $n_tot;
    if ($n_tot == 0) {
        $estats{me}{all}   = "na";
        $estats{mae}{all}  = "na";
        $estats{rmse}{all} = "na";
    } else {
        $estats{me}{all}   = $sum_diff    /$n_tot;
        $estats{mae}{all}  = $sum_absdiff /$n_tot;
        $estats{rmse}{all} = sqrt($sum_sqdiff /$n_tot);
    }
    if ($monthly) {
        for ($m=0; $m<12; $m++) {
            $mon = $mon_names[$m];
            if ($n_mon[$m] == 0) {
                $estats{me}{$mon}   = "na";
                $estats{mae}{$mon}  = "na";
                $estats{rmse}{$mon} = "na";
            } else {
                $estats{me}{$mon}   = $mon_diff[$m]    /$n_mon[$m];
                $estats{mae}{$mon}  = $mon_absdiff[$m] /$n_mon[$m];
                $estats{rmse}{$mon} = sqrt($mon_sqdiff[$m] /$n_mon[$m]);
            }
            $estats{n}{$mon} = $n_mon[$m];
        }
    }

    return (\%pstats, \%pstats2, \%estats);
}


############################################################################
#
# Compute vertical profile goodness-of-fit statistics for a single date/time
# using a W2 modeled profile and a measured vertical profile.
#
# These fit statistics are in program units, meaning Celsius for temperature
# and user units for others.
#
# If the measured profile is provided against depth, then the comparison
# to the model profile is in terms of depth.  If the measured profile is
# against fixed elevations, then the comparison to model results is in
# terms of elevation.
#
# Requires a single W2 vertical profile a matching measured vertical
# profile for the same date/time within a given tolerance.  The default
# date/time tolerance is 10 minutes.
#
# Modeled profiles may be interpolated vertically to match measured depths
# or elevations, at the user's preference.
#
# Computes the following:
#   ME   mean error
#   MAE  mean absolute error
#   RMSE root mean squared error
#
# Any measured data points marked as estimates will be excluded.
#
sub get_stats_single_profile {
    my ($id, $dt, $seg, $tol, $interp, $eldata_ref, $pdata_ref, $ref_pro_ref) = @_;
    my (
        $data_daily, $diff, $dist, $dt_ref, $dt_ref2, $found, $got_depth,
        $i, $lastpt, $lower, $mi, $mid, $n, $n_tot, $pdat, $ref_daily,
        $sum_absdiff, $sum_diff, $sum_sqdiff, $upper, $w2_layers,

        @depths, @el, @elevations, @estimated, @kb, @keys_data, @keys_ref,
        @ref_pdata, @valid_eldep, @valid_pdata, @w2_pro,

        %elev_data, %parm_data, %ref_data, %ref_profile, %ref_wsurf, %stats,
       );

    $interp      =  0 if (! defined($interp) || $interp ne "1");
    $tol         = 10 if (! defined($tol)    || $tol eq "");
    $tol         =  0 if ($tol < 0);
    $stats{n}    = "na";
    $stats{me}   = "na";
    $stats{mae}  = "na";
    $stats{rmse} = "na";

#   Get grid information
    @el = @{ $grid{$id}{el} };
    @kb = @{ $grid{$id}{kb} };

#   Get W2 profile data
    %elev_data = %{ $eldata_ref };
    %parm_data = %{ $pdata_ref  };

#   Exit early if W2 profile data are not defined for the date of interest
    return %stats if (! defined($elev_data{$dt}) || ! defined($parm_data{$dt}));

#   Get reference profile data
    %ref_profile = %{ $ref_pro_ref            };
    %ref_data    = %{ $ref_profile{pdata}     };
    %ref_wsurf   = %{ $ref_profile{ws_elev}   };
    @estimated   = @{ $ref_profile{estimated} };
    $got_depth   = ($ref_profile{elv_dep} eq "elevation") ? 0 : 1;
    if ($got_depth) {
        @depths     = @{ $ref_profile{depths} };
    } else {
        @elevations = @{ $ref_profile{elevations} };
    }
    $lastpt = ($got_depth) ? $#depths : $#elevations;

#   Get hash keys and determine whether the keys are daily or subdaily
    @keys_data  = keys %parm_data;
    @keys_ref   = keys %ref_data;
    $data_daily = (length($keys_data[0]) == 12) ? 0 : 1;
    $ref_daily  = (length($keys_ref[0])  == 12) ? 0 : 1;

#   Find a date/time match in the reference data within tol
    $dt_ref = $dt;
    if ($data_daily != $ref_daily) {
        if ($ref_daily) {
            $dt_ref = &nearest_daily_dt($dt);
            if (&get_dt_diff($dt, 10000 *$dt_ref) > $tol || ! defined($ref_data{$dt_ref})) {
                return %stats;
            }
        } else {
            $dt_ref .= "0000";
        }
    }
    if (! defined($ref_data{$dt_ref})) {
        return %stats if (($data_daily && $ref_daily) || $tol == 0);
        $found = 0;
        for ($mi=1; $mi<=$tol; $mi++) {
            $dt_ref2 = &adjust_dt($dt_ref, $mi);
            if (defined($ref_data{$dt_ref2})){
                $dt_ref = $dt_ref2;
                $found  = 1;
                last;
            }
            $dt_ref2 = &adjust_dt($dt_ref, -1 *$mi);
            if (defined($ref_data{$dt_ref2})){
                $dt_ref = $dt_ref2;
                $found  = 1;
                last;
            }
        }
        return %stats if (! $found);
    }

#   Compute model and data elevations. Skip any na values in the measured profile.
    $w2_layers   = $#{ $parm_data{$dt} } +1;
    @w2_pro      = @{ $parm_data{$dt} };
    @ref_pdata   = @{ $ref_data{$dt_ref} };
    @valid_pdata = ();
    @valid_eldep = ();
    for ($i=0; $i<=$lastpt; $i++) {
        next if ($ref_pdata[$i] eq "na");
        next if ($estimated[$i]);
        if ($got_depth) {
            push (@valid_eldep, $depths[$i]);
        } else {
            if ($ref_wsurf{$dt_ref} ne "na") {
                next if ($elevations[$i] > $ref_wsurf{$dt_ref} +0.1/3.28084);
            } else {
                next if ($elevations[$i] > $elev_data{$dt} +0.1/3.28084);
            }
            push (@valid_eldep, $elevations[$i]);
        }
        push (@valid_pdata, $ref_pdata[$i]);
    }

#   Find elevation or depth matches and compute model/data differences
    $n_tot = $sum_diff = $sum_absdiff = $sum_sqdiff = 0;
    for ($n=0; $n<=$#valid_pdata; $n++) {
        for ($i=0; $i<$w2_layers; $i++) {
            if ($i == 0) {
                $upper = $elev_data{$dt} +0.1/3.28084;
            } else {
                $upper = $el[$kb[$seg] -$w2_layers +1 +$i][$seg];
            }
            $lower = $el[$kb[$seg] -$w2_layers +2 +$i][$seg];
            if ($got_depth) {
                $upper = $elev_data{$dt} -$upper;
                $lower = $elev_data{$dt} -$lower;
            }
            if (($got_depth && $valid_eldep[$n] >= $upper && $valid_eldep[$n] < $lower)
                  || (! $got_depth && $valid_eldep[$n] <= $upper && $valid_eldep[$n] > $lower)) {
                $n_tot++;
                if ($interp && $w2_layers > 1) {
                    $mid = 0.5*($upper +$lower);

#                   Vertical interpolation of model profile using depths
                    if ($got_depth) {
                        if (($i == 0            && $valid_eldep[$n] <= $mid) ||
                            ($i == $w2_layers-1 && $valid_eldep[$n] >= $mid)) {
                            $pdat = $w2_pro[$i];
                        } elsif ($valid_eldep[$n] <= $mid) {
                            if ($i == 1) {
                                $dist = 0.5*($elev_data{$dt} -$el[$kb[$seg] -$w2_layers +2][$seg])
                                        +0.5*($lower -$upper);
                            } else {
                                $dist = 0.5*($el[$kb[$seg] -$w2_layers    +$i][$seg]
                                            -$el[$kb[$seg] -$w2_layers +1 +$i][$seg])
                                        +0.5*($lower -$upper);
                            }
                            $pdat = $w2_pro[$i] +($w2_pro[$i-1]-$w2_pro[$i])*($mid-$valid_eldep[$n])/$dist;
                        } else {
                            $dist = 0.5*($el[$kb[$seg] -$w2_layers +2 +$i][$seg]
                                        -$el[$kb[$seg] -$w2_layers +3 +$i][$seg])
                                    +0.5*($lower -$upper);
                            $pdat = $w2_pro[$i] +($w2_pro[$i+1]-$w2_pro[$i])*($valid_eldep[$n]-$mid)/$dist;
                        }

#                   Vertical interpolation of model profile using elevations
                    } else {
                        if (($i == 0            && $valid_eldep[$n] >= $mid) ||
                            ($i == $w2_layers-1 && $valid_eldep[$n] <= $mid)) {
                            $pdat = $w2_pro[$i];
                        } elsif ($valid_eldep[$n] >= $mid) {
                            if ($i == 1) {
                                $dist = 0.5*($elev_data{$dt} -$el[$kb[$seg] -$w2_layers +2][$seg])
                                        +0.5*($upper -$lower);
                            } else {
                                $dist = 0.5*($el[$kb[$seg] -$w2_layers    +$i][$seg]
                                            -$el[$kb[$seg] -$w2_layers +1 +$i][$seg])
                                        +0.5*($upper -$lower);
                            }
                            $pdat = $w2_pro[$i] +($w2_pro[$i-1]-$w2_pro[$i])*($valid_eldep[$n]-$mid)/$dist;
                        } else {
                            $dist = 0.5*($el[$kb[$seg] -$w2_layers +2 +$i][$seg]
                                        -$el[$kb[$seg] -$w2_layers +3 +$i][$seg])
                                    +0.5*($upper -$lower);
                            $pdat = $w2_pro[$i] +($w2_pro[$i+1]-$w2_pro[$i])*($mid-$valid_eldep[$n])/$dist;
                        }
                    }
                    $diff = $pdat -$valid_pdata[$n];

#               Or, no vertical interpolation. Match is somewhere in vertical range of model cell.
                } else {
                    $diff = $w2_pro[$i] -$valid_pdata[$n];
                }
                $sum_diff    += $diff;
                $sum_absdiff += abs($diff);
                $sum_sqdiff  += $diff *$diff;
                last;
            }
        }
    }

#   Compute the final parameter stats
    if ($n_tot > 0) {
        $stats{n}    = $n_tot;
        $stats{me}   = $sum_diff    /$n_tot;
        $stats{mae}  = $sum_absdiff /$n_tot;
        $stats{rmse} = sqrt($sum_sqdiff /$n_tot);
    }
    return %stats;
}

1;
