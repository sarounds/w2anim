############################################################################
#
#  W2 Animator
#  Data Retrieval Routines
#  Copyright (c) 2017-2026, Stewart A. Rounds
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
# List of subroutines
#
# Retrieval of USGS data:
#   get_USGS_sitelist
#   get_USGS_dataset
#
# Retrieval of USACE data:
#   get_USACE_sitelist
#   get_USACE_dataset
#

#
# Load important modules
#  LWP -- the World Wide Web library library for Perl
#  LWP::Protocol::https -- to handle https requests
#  LWP::UserAgent and Compress::Zlib may get loaded automatically
#  POSIX -- strftime used to help code time zones
#  URI::Escape -- to encode special characters for use in URLs
#  Text::CSV -- to parse csv text that contain commas in a quoted field
#  Time::Piece -- replaces localtime, gmtime and aids in date handling
#  JSON -- to decode JavaScript Object Notation output files
#
use strict;
use warnings;
use diagnostics;
use LWP;
use LWP::Protocol::https;
use POSIX 'strftime';
use URI::Escape;
use Text::CSV;
use Time::Piece;
use JSON;

#
# Shared global variables
#
our (
     $LWP_OK,

     @cwms_location_kinds, @tz_offsets, @usgs_pcodes,

     %cwms_offices, %cwms_parameters, %cwms_utc_offset, %huc_region,
     %huc_subregion, %huc_units, %site_type_codes, %state_code, %utc_offset,
    );

#
# Local variables
#
my (
    $LWP_UA_ver, $YYYY_MM_DD_fmt, $YYYY_MM_DD_HH_mm_fmt, $YYYY_MM_DD_HH_mm_ss_fmt,
   );

$YYYY_MM_DD_fmt          = "[12][0-9][0-9][0-9]-[01]?[0-9]-[0-3]?[0-9]";
$YYYY_MM_DD_HH_mm_fmt    = "[12][0-9][0-9][0-9]-[01]?[0-9]-[0-3]?[0-9][ T][012]?[0-9]:[0-5][0-9]";
$YYYY_MM_DD_HH_mm_ss_fmt = $YYYY_MM_DD_HH_mm_fmt . ":[0-5][0-9]";

#
# Check the LWP::UserAgent version. Older versions of LWP do not
# recognize TLS1.2 security protocols (required now), and old versions
# also do not recognize the ssl_opts argument.
#
$LWP_OK = 1;
if (! defined($LWP::UserAgent::VERSION) || $LWP::UserAgent::VERSION < 6 ) {
    $LWP_OK = 0;
    $LWP_UA_ver = (defined($LWP::UserAgent::VERSION)) ? $LWP::UserAgent::VERSION : "unknown";
    print "\nWarning: The LWP::UserAgent version ($LWP_UA_ver)\n",
          "is not recent enough to use the required TLS1.2\n",
          "security protocols. Please update your version of\n",
          "Perl and its LWP module.\n\n";
}


############################################################################
#
# Subroutine get_USGS_sitelist
#   Returns a list of sites and datasets that match user-specified criteria.
#   Accepts one of the following as the primary search method:
#    - a single site ID number or partial Site ID number
#    - a state/territory code
#    - one or more hydrologic unit codes (HUCs)
#   Optional search parameters include partial site name, pcode, site type, etc.
#
#   This routine uses the latest USGS Water Data APIs, as USGS Water Services
#   is scheduled to be retired in the first quarter of 2027.
#
#   This routine applies a two-step process, because the API does not provide
#   all of the required information in a single call.
#   1) The first call is to the monitoring-locations collection, which allows
#      for searching on the site ID, the HUC, the state/territory code, the
#      site name, and the site type.
#   2) The second call is to the time-series-metadata collection, which will use
#      a list of full Agency-SiteID codes to search on parameter codes and return
#      information on datasets of interest.
#
#   If searching by HUCs, this routine assumes that the input is from a menu
#   system that continually narrows down the choice. Sites are associated with
#   a 12-digit HUC, and the Water Data APIs allow for searches using incomplete
#   HUCs. The menu system should provide at least a 6-digit HUC basin, or
#   possibly a list of 8-digit HUC subbasins.
#
# Information passed to this routine includes:
#   method  -- major search method (SiteID, State, HUC)
#   code    -- search code that goes with the method
#   idmatch -- type of site ID search (any, start, end, exact)
#   pcode   -- USGS parameter code
#   name    -- search term for a site name
#   nmatch  -- type of name search (any, start, end, exact)
#   dtype   -- data type, iv or dv (instantaneous or daily values)
#   dvstat  -- daily statistic for daily values (min, max, mean, sum, median)
#   status  -- site status code (all, active, inactive)
#   stype   -- site type code
#
#   parent  -- the parent window, used for error messages
#   msg_txt -- name of a label widget for status messages
#
sub get_USGS_sitelist {
    my ($parent, $msg_txt, %args) = @_;
    my (
        $agcy_field, $bdate, $bdate_field, $code, $ContentLength_hdr,
        $csv, $dataset, $dtype, $dvstat, $edate, $edate_field, $filter,
        $filter1, $filter2, $filter3, $found_huc8, $huc, $huc6, $i,
        $id_field, $idmatch, $indx, $jd_diff, $jd_now, $len, $method,
        $msg, $name, $name2, $name3, $name_field, $nmatch, $nsites,
        $pcode, $pcode_field, $pname_field, $response, $site, $site_field,
        $sitelist, $status, $stat, $stat_field, $stype, $sublc_field, $tm,
        $try, $tz_cd, $tz_field, $ua, $units_field, $url, $wild1, $wild2,

        @count, @hucs, @fields, @lines, @sites, @units, @valid_hucs, @vals,

        %results,
       );

    $nsites  = 0;
    %results = ();
    $method  = (defined($args{method}))  ? $args{method}  : "";
    $code    = (defined($args{code}))    ? $args{code}    : "";
    $idmatch = (defined($args{idmatch})) ? $args{idmatch} : "";
    $pcode   = (defined($args{pcode}))   ? $args{pcode}   : "";
    $name    = (defined($args{name}))    ? $args{name}    : "";
    $nmatch  = (defined($args{nmatch}))  ? $args{nmatch}  : "";
    $dtype   = (defined($args{dtype}))   ? $args{dtype}   : "";
    $dvstat  = (defined($args{dvstat}))  ? $args{dvstat}  : "";
    $status  = (defined($args{status}))  ? $args{status}  : "";
    $stype   = (defined($args{stype}))   ? $args{stype}   : "";

    if ($method eq "" || $method !~ /^(HUC|State|SiteID)$/) {
        return (0) if &pop_up_error($parent, "Please choose a search method:\n"
                                           . "HUC, State, or Site ID.");
    }
    $pcode =~ s/[^0-9]//g;
    $pcode = "" if (length($pcode) != 5);
    $name  =~ s/^\s+// if ($nmatch =~ /exact|start/);
    $name  =~ s/\s+$// if ($nmatch =~ /exact|end/);
    $dtype = "" if ($dtype ne "iv" && $dtype ne "dv");
    if ($dtype eq "dv") {
        if ($dvstat eq "mean") {
            $dvstat = "00003";
        } elsif ($dvstat eq "max") {
            $dvstat = "00002";
        } elsif ($dvstat eq "min") {
            $dvstat = "00001";
        } elsif ($dvstat eq "median") {
            $dvstat = "00008";
        } elsif ($dvstat eq "sum") {
            $dvstat = "00006";
        } else {
            $dvstat = "";
        }
    }

  # The first step is a call to the monitoring-locations collection.
  # This allows a search on the site ID number, HUC, state code, site name, and site type.
    $url = 'https://api.waterdata.usgs.gov/ogcapi/v0/collections/monitoring-locations/items?f=csv'
         . '&lang=en-US&limit=50000&skipGeometry=true&offset=0'
         . '&properties=agency_code,monitoring_location_number,monitoring_location_name,'
         .             'time_zone_abbreviation'
         . '&sortby=agency_code,monitoring_location_number';
    $filter = $filter1 = $filter2 = $filter3 = "";

    if ($method eq "HUC") {
        $code =~ s/[^0-9,]//g;
        @hucs = split(/,/, $code);

      # Find valid HUCs
        @valid_hucs = ();
        $found_huc8 = 0;
        for ($i=0; $i<=$#hucs; $i++) {
            $len = length($hucs[$i]);
            if ($len == 6) {
                if (&list_match($hucs[$i], keys %huc_units) >= 0) {
                    push (@valid_hucs, $hucs[$i]);
                }
            } elsif ($len == 8) {
                $huc6 = substr($hucs[$i],0,6);
                if (&list_match($huc6, keys %huc_units) >= 0) {
                    @units = @{ $huc_units{$huc6}{units} };
                    $indx  = substr($hucs[$i],6,2);
                    if (($indx eq "00" && $#units == 0) ||
                        ($indx+0 <= $#units+1)) {
                        push (@valid_hucs, $hucs[$i]);
                        $found_huc8++;
                    }
                }
            }
        }
        if ($#valid_hucs < 0) {
            return (0) if &pop_up_error($parent, "The supplied HUC code was not valid.\n"
                                               . "Please try again.");
        }

      # Figure out which HUCs to use as search terms.
      # This search will use either a 6-digit HUC or one or more 8-digit HUCs.
      # The database has 12-digit HUCs assigned to each site, and partial HUC searches are allowed.
      # For multiple 8-digit HUCs, a filter is required.
        $huc = "";
        for ($i=0; $i<=$#valid_hucs; $i++) {
            $len = length($valid_hucs[$i]);
            next if ($found_huc8 > 0 && $len != 8);
            if ($len == 6 || ($len == 8 && $found_huc8 == 1)) {
                $huc = $valid_hucs[$i];
                last;
            } else {
                $filter1 .= uri_escape(' OR ') if ($i > 0);
                $filter1 .= uri_escape('hydrologic_unit_code LIKE \'')
                          . $valid_hucs[$i] . uri_escape('%\'');
            }
        }
        if ($huc ne "") {
            $url .= '&hydrologic_unit_code=' . $huc;
        }

    } elsif ($method eq "State") {
        $code =~ s/[^0-9]//g;
        if (&list_match($code, values %state_code) < 0) {
            return (0) if &pop_up_error($parent, "Invalid state or territory code.\n"
                                               . "Please try again.");
        }
        $url .= '&state_code=' . $code;

    } elsif ($method eq "SiteID") {
        $code =~ s/[^0-9]//g;
        if ($idmatch =~ /exact/ && (length($code) < 8 || length($code) > 15)) {
            return (0) if &pop_up_error($parent, "Site ID must be between 8 and 15 digits.\n"
                                               . "Please try again.");
        }
        if ($idmatch eq "exact") {
            $url .= '&monitoring_location_number=' . $code;
        } else {
            $filter1 = uri_escape('monitoring_location_number LIKE \'');
            if ($idmatch eq "start") {
                $filter1 .= $code . uri_escape('%\'');
            } elsif ($idmatch eq "end") {
                $filter1 .= uri_escape('%') . $code . uri_escape('\'');
            } elsif ($idmatch eq "any") {
                $filter1 .= uri_escape('%') . $code . uri_escape('%\'');
            }
        }
    }

  # Add the site type to the search, if provided
    $stype =~ s/[^A-Z]//g;
    if ($stype ne "") {
        if (&list_match($stype, values %site_type_codes) < 0) {
            return (0) if &pop_up_error($parent, "Invalid site type specified.\n"
                                               . "Please try again.");
        }
        if ($stype =~ /^(GW|LA|OC|SB|ST)$/) {
            $filter2 = uri_escape("site_type_code LIKE '") . $stype . uri_escape("\%'");
        } else {
            $url .= '&site_type_code=' . $stype;
        }
    }

  # A partial site name may be added to the search, but not if the method is SiteID
    if ($method eq "HUC" || $method eq "State") {
        if ($name ne "") {
            $name  =~ s/\s+/ /g;
            $name2 = uc($name);          # Try uppercase
            $name3 = &titlecase($name);  # Try first-letter capitalized, with exceptions
            $name3 =~ s/Rm /RM /g;
            $name3 =~ s/Rm$/RM/g;
            $name2 = "" if ($name2 eq $name);
            $name3 = "" if ($name3 eq $name);
            $name  = uri_escape($name);
            $name2 = uri_escape($name2) if ($name2 ne "");
            $name3 = uri_escape($name3) if ($name3 ne "");

            $wild1 = $wild2 = "";
            $wild1 = '%' if ($nmatch =~ /any|end/);
            $wild2 = '%' if ($nmatch =~ /any|start/);

            $filter3 = uri_escape("monitoring_location_name LIKE '$wild1") . $name
                     . uri_escape("$wild2'");
            if ($name2 ne "") {
                $filter3 .= uri_escape(" OR monitoring_location_name LIKE '$wild1") . $name2
                          . uri_escape("$wild2'");
            }
            if ($name3 ne "") {
                $filter3 .= uri_escape(" OR monitoring_location_name LIKE '$wild1") . $name3
                          . uri_escape("$wild2'");
            }
        }
    }

  # Tack on the filter, if present
    if ($filter1 ne "" && $filter1 =~ /\%20OR\%20/ && ($filter2 ne "" || $filter3 ne "")) {
        $filter1 = uri_escape('(') . $filter1 . uri_escape(')');
    }
    if ($filter3 ne "" && $filter3 =~ /\%20OR\%20/ && ($filter1 ne "" || $filter2 ne "")) {
        $filter3 = uri_escape('(') . $filter3 . uri_escape(')');
    }
    $filter = $filter1;
    if ($filter ne "") {
        if ($filter2 ne "") {
            $filter .= uri_escape(' AND ') . $filter2;
        }
        if ($filter3 ne "") {
            $filter .= uri_escape(' AND ') . $filter3;
        }
    } elsif ($filter2 ne "") {
        $filter = $filter2;
        if ($filter3 ne "") {
            $filter .= uri_escape(' AND ') . $filter3;
        }
    } elsif ($filter3 ne "") {
        $filter = $filter3;
    }
    if ($filter ne "") {
        $url .= '&filter=' . $filter;
    }

  # Start an LWP client. The LWP::UserAgent version has already been checked.  Older versions
  # of LWP do not recognize the required TLS1.2 security protocols, and old versions also do
  # not recognize the ssl_opts argument.
    $ua = LWP::UserAgent->new(ssl_opts => { SSL_version => 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11' });
    $ua->agent("WebRetriever/0.1 ");
    $ContentLength_hdr = HTTP::Headers->new('Content-Length' => 0);

    $msg_txt->configure(-text => "Searching for sites... Please wait...");
    Tkx::update();

  # Make a call to USGS Water Data APIs to get a site list and other site-related metadata.
    $try = 0;
    while (++$try <= 3) {
        $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
        unless ($response->is_success) {
            if ($try < 3) { sleep 1; next; }
            $msg = "ERROR:  Unable to retrieve site\ninformation from USGS Water Data APIs.";
            @lines = split(/\n/, $response->as_string);
            if ($lines[0] =~ /[4-5][0-9][0-9] /) {
                $lines[0] =~ s/[4-5][0-9][0-9] //;
                $msg .= "\nReason: $lines[0]." if ($lines[0] !~ /404/);
            }
            return ($nsites, %results) if &pop_up_error($parent, $msg);
        }
        @lines = split(/\n/, $response->content);

      # First line should be headers
        if ($#lines >= 0) {
            last if ($lines[0] =~ /agency_code/ &&
                     $lines[0] =~ /monitoring_location_number/ &&
                     $lines[0] =~ /monitoring_location_name/ &&
                     $lines[0] =~ /time_zone_abbreviation/);
        }

      # Fail after trying multiple times
        if ($try >= 3) {
            return ($nsites, %results);
        }
        sleep 1;  # pause for a second, if try failed
    }

  # Return if retrieval has no data
    if ($#lines == 0) {
        return ($nsites, %results);
    }

  # Filter the results.
    $lines[0]   =~ s/\s+$//;
    @fields     = split(/,/, $lines[0]);
    $agcy_field = &list_match('agency_code',                @fields);  # agency code
    $site_field = &list_match('monitoring_location_number', @fields);  # site ID
    $name_field = &list_match('monitoring_location_name',   @fields);  # site name
    $tz_field   = &list_match('time_zone_abbreviation',     @fields);  # time zone code

  # Site name may include a comma, so parse with Text::CSV.
    $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    for ($i=1; $i<=$#lines; $i++) {
        $lines[$i] =~ s/\s+$//;
        if ($lines[$i] =~ /\"/) {
            if ($csv->parse($lines[$i])) {
                @vals = $csv->fields();
            } else {
                &pop_up_error($parent, "ERROR:  Problem parsing csv output\n"
                                     . "of site info from USGS Water Data APIs.\n"
                                     . $csv->error_input());
                next;
            }
        } else {
            @vals = split(/,/, $lines[$i]);
        }
        $site = $vals[$site_field];
        next if (&list_match($site, keys %results) >= 0);
        $results{$site}{agency} = $vals[$agcy_field];
        $results{$site}{name}   = $vals[$name_field];
        $results{$site}{tz_cd}  = $vals[$tz_field];
        $nsites++;
    }

  # Now that a list of sites is in hand, the next step is to find datasets that match
  # user-specified criteria. This second call to USGS Water Data APIs will obtain
  # dataset IDs, parameter and statistic codes, starting and ending dates, sublocations,
  # and measurement units.
    if ($nsites > 0) {
        $url = 'https://api.waterdata.usgs.gov/ogcapi/v0/collections/time-series-metadata/items?f=csv'
             . '&lang=en-US&limit=50000&skipGeometry=true&offset=0'
             . '&properties=id,monitoring_location_id,parameter_code,statistic_id,begin_utc,end_utc,'
             .      'computation_period_identifier,sublocation_identifier,parameter_name,unit_of_measure'
             . '&sortby=monitoring_location_id,parameter_code,statistic_id';
        $filter = "computation_period_identifier NOT IN ('Water Year')";

      # Stuff all of the site IDs into the search (unfortunate to clutter the URL, but gotta do it)
        @sites    = sort numerically keys %results;
        $sitelist = $results{$sites[0]}{agency} . "-" . $sites[0];
        @count    = (0) x @sites;
        for ($i=1; $i<=$#sites; $i++) {
            $sitelist .= ',' . $results{$sites[$i]}{agency} . "-" . $sites[$i];
        }
        $url .= '&monitoring_location_id=' . $sitelist;

      # Include a USGS pcode in the search, if requested
        if ($pcode ne "") {
            if (&list_match($pcode, @usgs_pcodes) >= 0) {
                $url .= '&parameter_code=' . $pcode;
            }
        }

      # Require a certain data type (iv = instantaneous values [subdaily], dv = daily values)
      # and specify the desired statistic code to retrieve the requested datasets.
        if ($dtype eq "iv") {
            $url .= '&statistic_id=00011';
        } elsif ($dtype eq "dv") {
            if ($dvstat eq "") {
                $url .= '&statistic_id=00001,00002,00003,00006,00008';
            } else {
                $url .= '&statistic_id=' . $dvstat;
            }
        }

      # Add the filter
        $url .= '&filter=' . uri_escape($filter);

        $msg_txt->configure(-text => "Searching for datasets... Please wait...");
        Tkx::update();

      # Make a call to USGS Water Data APIs to get available dataset information.
        $try = 0;
        while (++$try <= 3) {
            $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
            unless ($response->is_success) {
                if ($try < 3) { sleep 1; next; }
                $msg = "ERROR:  Unable to retrieve dataset\ninformation from USGS Water Data APIs.";
                @lines = split(/\n/, $response->as_string);
                if ($lines[0] =~ /[4-5][0-9][0-9] /) {
                    $lines[0] =~ s/[4-5][0-9][0-9] //;
                    $msg .= "\nReason: $lines[0]." if ($lines[0] !~ /404/);
                }
                return ($nsites, %results) if &pop_up_error($parent, $msg);
            }
            @lines = split(/\n/, $response->content);

          # First line should be headers
            if ($#lines >= 0) {
                last if ($lines[0] =~ /^id,|,id$|,id,/ &&
                         $lines[0] =~ /monitoring_location_id/ &&
                         $lines[0] =~ /parameter_code/ &&
                         $lines[0] =~ /statistic_id/ &&
                         $lines[0] =~ /begin_utc/ &&
                         $lines[0] =~ /end_utc/ &&
                         $lines[0] =~ /computation_period_identifier/ &&
                         $lines[0] =~ /sublocation_identifier/ &&
                         $lines[0] =~ /parameter_name/ &&
                         $lines[0] =~ /unit_of_measure/);
            }

          # Fail after trying multiple times
            if ($try >= 3) {
                return ($nsites, %results);
            }
            sleep 1;  # pause for a second, if try failed
        }

      # Filter the results.
        $lines[0]    =~ s/\s+$//;
        @fields      = split(/,/, $lines[0]);
        $id_field    = &list_match('id',                     @fields);  # unique dataset id
        $site_field  = &list_match('monitoring_location_id', @fields);  # site ID w/ agency code
        $pcode_field = &list_match('parameter_code',         @fields);  # pcode
        $pname_field = &list_match('parameter_name',         @fields);  # parameter name
        $stat_field  = &list_match('statistic_id',           @fields);  # stat code
        $bdate_field = &list_match('begin_utc',              @fields);  # UTC begin date, available data
        $edate_field = &list_match('end_utc',                @fields);  # UTC end date, available data
        $sublc_field = &list_match('sublocation_identifier', @fields);  # sublocation
        $units_field = &list_match('unit_of_measure',        @fields);  # measurement units

      # For a site-status check, get a reference date
        if ($status =~ /^(active|inactive)$/) {
            $tm     = localtime(time);
            $jd_now = &datelabel2jdate($tm->ymd);
        }

      # Make a list of sites that match the search criteria
      # and return that list along with types of available datasets
        for ($i=1; $i<=$#lines; $i++) {
            $lines[$i] =~ s/\s+$//;
            if ($lines[$i] =~ /\"/) {
                if ($csv->parse($lines[$i])) {
                    @vals = $csv->fields();
                } else {
                    &pop_up_error($parent, "ERROR:  Problem parsing csv output of\n"
                                         . "dataset info from USGS Water Data APIs.\n"
                                         . $csv->error_input());
                    next;
                }
            } else {
                @vals = split(/,/, $lines[$i]);
            }
            ($site = $vals[$site_field]) =~ s/^.+\-(\d+)$/$1/;

            next if (&list_match($site, @sites) < 0);
            next if ($pcode ne "" && $vals[$pcode_field] ne $pcode);
            if ($dtype eq "iv") {
                next if ($vals[$stat_field] ne '00011');
            } elsif ($dtype eq "dv") {
                next if ($dvstat ne "" && $vals[$stat_field] ne $dvstat);
                next if ($dvstat eq "" && $vals[$stat_field] !~ /00001|00002|00003|00006|00008/);
            } else {
                next if ($vals[$stat_field] !~ /00001|00002|00003|00006|00008|00011/);
            }
            next if (! defined($vals[$bdate_field]) || $vals[$bdate_field] !~ /^${YYYY_MM_DD_HH_mm_fmt}/);
            next if (! defined($vals[$edate_field]) || $vals[$edate_field] !~ /^${YYYY_MM_DD_HH_mm_fmt}/);

          # Convert begin and end dates to local time
            $tz_cd = $results{$site}{tz_cd};
            $bdate = $vals[$bdate_field];
            $edate = $vals[$edate_field];
            if (defined($utc_offset{$tz_cd})) {
                $bdate = &adjust_date($bdate, $utc_offset{$tz_cd} *60);
                $edate = &adjust_date($edate, $utc_offset{$tz_cd} *60);
            }
            $bdate = substr($bdate,0,10);
            $edate = substr($edate,0,10);

          # Check to see if a dataset would be considered active
            if ($status =~ /^(active|inactive)$/) {
                $jd_diff = $jd_now - &datelabel2jdate($edate);
                next if ($status eq "active"   && $jd_diff >  365);
                next if ($status eq "inactive" && $jd_diff <= 365);
            }

            $stat = $vals[$stat_field];
            if ($stat eq "00011") {
                $dataset = $vals[$pcode_field] . "_iv";
            } elsif ($stat =~ /00001|00002|00003|00006|00008/) {
                $dataset = $vals[$pcode_field] . "_dv_" . $stat;
            }
            if (defined($vals[$sublc_field])) {
                $dataset .= "_at_" . $vals[$sublc_field];
            }
            $results{$site}{$dataset}{date_range} = $bdate . " to " . $edate;
            $results{$site}{$dataset}{ts_id}      = $vals[$id_field];
            $results{$site}{$dataset}{pname}      = $vals[$pname_field];
            $results{$site}{$dataset}{units}      = $vals[$units_field];
            if (defined($vals[$sublc_field])) {
                $results{$site}{$dataset}{subloc} = $vals[$sublc_field];
            } else {
                $results{$site}{$dataset}{subloc} = "";
            }
            $count[&list_match($site, @sites)]++;
        }
    }

  # Remove any results for sites that have no datasets
    for ($i=0; $i<=$#sites; $i++) {
        if ($count[$i] == 0) {
            delete $results{$sites[$i]};
            $nsites--;
        }
    }

    $msg_txt->configure(-text => "");
    Tkx::update();

  # Return the site information
    return ($nsites, %results);
}


############################################################################
#
# Subroutine get_USGS_dataset
#   Returns a USGS time-series dataset that matches user-specified criteria.
#
# Information passed to this routine includes:
#   file    -- output file
#   ts_id   -- USGS time-series ID
#   site_id -- USGS site ID number (Agency-SiteID)
#   subloc  -- sublocation name
#   sname   -- USGS site name
#   pcode   -- USGS parameter code
#   pname   -- USGS parameter name
#   units   -- measurement units
#   dtype   -- data type, iv or dv (instantaneous or daily values)
#   dvstat  -- daily statistic for daily values (Min, Max, Mean, Sum, Median)
#   bdate   -- begin date (YYYY-MM-DD)
#   edate   -- end date (YYYY-MM-DD)
#   tz_cd   -- time zone code (e.g. PST)
#   tz_off  -- time zone offset (default is +00:00)
#
#   parent  -- the parent window, used for error messages
#   msg_txt -- name of a label widget for status messages
#
sub get_USGS_dataset {
    my ($parent, $msg_txt, %args) = @_;
    my (
        $add_min, $agency, $base_url, $bdate, $ContentLength_hdr, $date,
        $date1, $date_range, $date_range_sav, $done, $dt, $dtype, $dvstat,
        $edate, $end_date, $fh, $file, $fmt, $hdr, $hh, $hms, $hrs, $i,
        $jd1, $jd2, $last_date, $line, $local_tz, $mm, $msg, $part, $pcode,
        $pname, $pos, $response, $sec, $sep, $site, $site_id, $site_no,
        $sname, $stop_date, $subloc, $tm, $try, $ts_id, $tz, $tz_cd,
        $tz_off, $ua, $units, $url,

        @date_ranges, @end_dates, @lines, @stop_dates, @tmp,
       );

    $file    = (defined($args{file}))    ? $args{file}    : "";
    $ts_id   = (defined($args{ts_id}))   ? $args{ts_id}   : "";
    $site_id = (defined($args{site_id})) ? $args{site_id} : "";
    $subloc  = (defined($args{subloc}))  ? $args{subloc}  : "";
    $sname   = (defined($args{sname}))   ? $args{sname}   : "";
    $pcode   = (defined($args{pcode}))   ? $args{pcode}   : "";
    $pname   = (defined($args{pname}))   ? $args{pname}   : "";
    $units   = (defined($args{units}))   ? $args{units}   : "";
    $dtype   = (defined($args{dtype}))   ? $args{dtype}   : "";
    $dvstat  = (defined($args{dvstat}))  ? $args{dvstat}  : "";
    $bdate   = (defined($args{bdate}))   ? $args{bdate}   : "";
    $edate   = (defined($args{edate}))   ? $args{edate}   : "";
    $tz_cd   = (defined($args{tz_cd}))   ? $args{tz_cd}   : "";
    $tz_off  = (defined($args{tz_off}))  ? $args{tz_off}  : "+00:00";

    $fmt = ($file =~ /\.csv$/i) ? "csv" : "tab";
    if ($dtype eq "dv") {
        $add_min = 0;
    } else {
        if ($tz_off eq "" || $tz_off eq "+00:00" || &list_match($tz_off, @tz_offsets) < 0
                                                 || ! defined($utc_offset{$tz_cd})) {
            $add_min = 0;
            $tz_off  = "+00:00";
        } else {
            ($hh, $mm) = split(/:/, substr($tz_off,1));
            $add_min   = $hh *60 + $mm;
            $add_min  *= -1 if (substr($tz_off,0,1) eq "-");
        }
    }
    ($agency  = $site_id) =~ s/^(.*)-\d+$/$1/;
    ($site_no = $site_id) =~ s/^.*-(\d+)$/$1/;

  # Construct a URL to retrieve the data of interest.
  # Use the time-series ID. It is supposed to be unique, and it is the best way
  # to specify a single dataset, particularly if a sublocation is included.
  # For subdaily data retrievals, advance the end date by 1 day.
  # Return fields include only the date/time, value, approval, and qualifiers.
    if ($dtype eq "iv") {
        $base_url = 'https://api.waterdata.usgs.gov/ogcapi/v0/collections/continuous/items?f=csv';
        $edate    = &adjust_dt_by_day($edate, 1);
    } else {
        $base_url = 'https://api.waterdata.usgs.gov/ogcapi/v0/collections/daily/items?f=csv';
    }
    $base_url .= '&lang=en-US&offset=0&skipGeometry=true'
               . '&properties=time,value,approval_status,qualifier'
               . '&time_series_id=' . $ts_id;

  # Need to specify the date range in RFC 3339 format (YYYY-MM-DDTHH:mm:ss.sss+HH.MM)
  # The begin and end dates should have been passed in YYYY-MM-DD format.
  # For subdaily data, specify the date range in the local standard time.
  # For subdaily requests, each call is limited to no more than 1100 days of data.
  # For daily data, it should be okay to specify dates as YYYY-MM-DD only.
    $jd1 = &datelabel2jdate($bdate);
    $jd2 = &datelabel2jdate($edate);
    @date_ranges = @stop_dates = @end_dates = ();
    if ($dtype eq "iv") {
        if (! defined($utc_offset{$tz_cd}) || $utc_offset{$tz_cd} == 0) {
            $tz = "Z";
            $stop_date = $edate . ' 00:00:00';
        } else {
            $hh = $utc_offset{$tz_cd};
            $tz = sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60);
            $stop_date = &adjust_date($edate . ' 00:00', -1* $hh*60) . ':00';
        }
        $date_range     = $bdate . 'T00:00:00' . $tz . '/' . $edate . 'T00:00:00' . $tz;
        $end_date       = $edate . 'T00:00:00' . $tz;
        $date_range_sav = $date_range;
        if ($jd2 -$jd1 +1 > 1100) {
            $date1 = $bdate;
            while ($jd1 +1000 < $jd2) {
                $date = &jdate2datelabel($jd1 +1000, "YYYY-MM-DD");
                $hms  = ($#date_ranges >= 0) ? 'T00:00:01' : 'T00:00:00';
                if (! defined($utc_offset{$tz_cd}) || $utc_offset{$tz_cd} == 0) {
                    $stop_date = $date  . ' 00:00:00';
                } else {
                    $stop_date = &adjust_date($date . ' 00:00', -1* $hh*60) . ':00';
                }
                $date_range = $date1 . $hms . $tz . '/' . $date . 'T00:00:00' . $tz;
                $end_date   = $date  . 'T00:00:00' . $tz;
                push (@date_ranges, $date_range);
                push (@stop_dates, $stop_date);
                push (@end_dates, $end_date);
                $jd1  += 1000;
                $date1 = &jdate2datelabel($jd1, "YYYY-MM-DD");
            }
            if ($jd1 < $jd2) {
                $hms = ($#date_ranges >= 0) ? 'T00:00:01' : 'T00:00:00';
                if (! defined($utc_offset{$tz_cd}) || $utc_offset{$tz_cd} == 0) {
                    $stop_date = $edate . ' 00:00:00';
                } else {
                    $stop_date = &adjust_date($edate . ' 00:00', -1* $hh*60) . ':00';
                }
                $date_range = $date1 . $hms . $tz . '/' . $edate . 'T00:00:00' . $tz;
                $end_date   = $edate . 'T00:00:00' . $tz;
                push (@date_ranges, $date_range);
                push (@stop_dates, $stop_date);
                push (@end_dates, $end_date);
            }
            $date_range = shift @date_ranges;
            $stop_date  = shift @stop_dates;
            $end_date   = shift @end_dates;
        }
        $base_url .= '&limit=30000'; 
    } else {
        if ($jd2 -$jd1 +1 > 50000) {
            $date1 = $bdate;
            while ($jd1 +40000 < $jd2) {
                $date = &jdate2datelabel($jd1 +40000, "YYYY-MM-DD");
                $date_range = $date1 . 'T00:00:00Z/' . $date . 'T00:00:00Z';
                push (@date_ranges, $date_range);
                $jd1  += 40001;
                $date1 = &jdate2datelabel($jd1, "YYYY-MM-DD");
            }
            if ($jd1 < $jd2) {
                $date_range = $date1 . 'T00:00:00Z/' . $edate . 'T00:00:00Z';
                push (@date_ranges, $date_range);
            }
        } else {
            $date_range = $bdate . 'T00:00:00Z/' . $edate . 'T00:00:00Z';
            push (@date_ranges, $date_range);
        }
        $date_range = shift @date_ranges;
        $base_url  .= '&limit=50000' . '&sortby=time'; 
    }
    $url = $base_url . '&datetime=' . uri_escape($date_range);

  # Start an LWP client. The LWP::UserAgent version has already been checked.  Older versions
  # of LWP do not recognize the required TLS1.2 security protocols, and old versions also do
  # not recognize the ssl_opts argument.
    $ua = LWP::UserAgent->new(ssl_opts => { SSL_version => 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11' });
    $ua->agent("WebRetriever/0.1 ");
    $ContentLength_hdr = HTTP::Headers->new('Content-Length'  => 0,
                                            'Accept-Encoding' => 'gzip, deflate');

  # Try to retrieve the dataset.
  # Iterate until all data are retrieved. It may take more than one call, given that
  # the retrievals are limited to 50,000 data points at a time.
    $msg_txt->configure(-text => "Requesting data... Please wait...");
    Tkx::update();

    $part  = 1;
    @lines = @tmp = ();
    $done  = 0;
    until ($done) {
        $try = 0;
        while (++$try <= 3) {
            $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
            unless ($response->is_success) {
                if ($try < 3) { sleep 1; next; }
                $msg = "ERROR:  Unable to retrieve\ndata from USGS Water Data APIs.";
                @tmp = split(/\n/, $response->as_string);
                if ($tmp[0] =~ /[4-5][0-9][0-9] /) {
                    $tmp[0] =~ s/[4-5][0-9][0-9] //;
                    $msg .= "\nReason: $tmp[0]." if ($tmp[0] !~ /404/);
                }
                undef @tmp;
                undef @lines;
                return 0 if &pop_up_error($parent, $msg);
            }
            @tmp = split(/\n/, $response->decoded_content);

          # First line should be headers
            if ($#tmp >= 0) {
                last if ($tmp[0] =~ /time/ &&
                         $tmp[0] =~ /value/ &&
                         $tmp[0] =~ /approval_status/ &&
                         $tmp[0] =~ /qualifier/);
            }

          # Fail after trying multiple times
            if ($try >= 3) {
                undef @tmp;
                undef @lines;
                return 0;
            }
            sleep 1;  # pause for a second, if try failed
        }

      # If the subdaily request returned 30001 lines, another retrieval may be needed.
      # 50,000 lines is the API limit; the subdaily limit used here is 30,000.
      # Assume that the retrieved date/time is in the format YYYY-MM-DD HH:mm:ss+XX:XX
        if ($dtype eq "iv") {
            if ($#tmp == 30000) {
                ($line = $tmp[$#tmp]) =~ s/\s+$//;
                ($last_date = $line) =~ s/^.*(${YYYY_MM_DD_HH_mm_ss_fmt}).*$/$1/;
                ($tz        = $line) =~ s/^.*${YYYY_MM_DD_HH_mm_ss_fmt}([+-]\d\d:\d\d),.*$/$1/;
                $last_date =~ s/T/ /;
                if ($last_date ge $stop_date) {
                    if ($#date_ranges >= 0) {
                        $date_range = shift @date_ranges;
                        $stop_date  = shift @stop_dates;
                        $end_date   = shift @end_dates;
                    } else {
                        $done = 1;
                    }
                } else {
                    $tz = "+00:00" if (! defined($tz));
                    $last_date  = &add_one_sec($last_date);
                    $date_range = $last_date . $tz . '/' . $end_date;
                }
            } else {
                if ($#date_ranges >= 0) {
                    $date_range = shift @date_ranges;
                    $stop_date  = shift @stop_dates;
                    $end_date   = shift @end_dates;
                } else {
                    $done = 1;
                }
            }

      # For daily data, may need to specify another date range and ask for more data.
        } else {
            if ($#date_ranges >= 0) {
                $date_range = shift @date_ranges;
            } else {
                $done = 1;
            }
        }
        shift @tmp;
        push (@lines, @tmp);
        undef @tmp;
        if (! $done) {
            $url = $base_url . '&datetime=' . uri_escape($date_range);
            $part++;
            $msg_txt->configure(-text => "Requesting data, part $part... Please wait...");
            Tkx::update();
        }
    }

  # Open the output file
    $msg_txt->configure(-text => "Opening output file...");
    Tkx::update();
    open ($fh, ">$file") or ((return 0) && &pop_up_error($parent, "Unable to open output file:\n$file."));

  # Create a header that conforms to the chosen format, provides useful information,
  # and looks somewhat like the old default format from USGS Water Services.
    $tm       = localtime(time);
    $local_tz = $tm->strftime("%z");
    $local_tz = "UTC" . substr($local_tz,0,-2) . ":" . substr($local_tz,-2) if ($local_tz !~ /:/);
    $date     = $tm->ymd . " " . $tm->hms . "  TZ: " . $local_tz;

    $hdr = "# -------------------- USGS Water Data Retrieval --------------------\n"
         . "# Some of the data retrieved from the U.S. Geological Survey database may not\n"
         . "# have received final approval. Such data values are qualified as provisional\n"
         . "# and are subject to revision. Provisional data are released on the condition\n"
         . "# that neither the USGS nor the United States Government may be held liable\n"
         . "# for any damages resulting from their use.\n"
         . "#  See https://waterdata.usgs.gov/provisional-data-statement/\n"
         . "#\n"
         . "# Retrieval Info: https://api.waterdata.usgs.gov/\n"
         . "# Contact:        gs-w_waterdata_support\@usgs.gov\n"
         . "# Retrieved:      $date\n"
         . "#\n"
         . "# Data in this file are from the following site:\n"
         . "#  Agency:       $agency\n"
         . "#  Site Number:  $site_no\n"
         . "#  Site ID:      $site_id\n";

    if ($fmt eq "csv" && $sname =~ /,/) {
        $hdr .= "\"#  Site Name:    $sname\"\n";
    } else {
        $hdr .= "#  Site Name:    $sname\n";
    }
    if ($subloc ne "") {
        if ($fmt eq "csv" && $subloc =~ /,/) {
            $hdr .= "\"#  Sublocation:  $subloc\"\n";
        } else {
            $hdr .= "#  Sublocation:  $subloc\n";
        }
    }
    if (defined($utc_offset{$tz_cd})) {
        $hh = $utc_offset{$tz_cd};
        $tz = $tz_cd . " (UTC" . sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60) . ")";
    } else {
        $tz = $tz_cd;
    }
    $hdr .= "#  Time Zone:    $tz\n"
          . "#\n"
          . "# The dataset represents a specific time series:\n"
          . "#  Time Series ID:     $ts_id\n"
          . "#  Parameter Code:     $pcode\n";

    if ($fmt eq "csv" && $pname =~ /,/) {
        $hdr .= "\"#  Parameter Name:     $pname\"\n";
    } else {
        $hdr .= "#  Parameter Name:     $pname\n";
    }
    if ($fmt eq "csv" && $units =~ /,/) {
        $hdr .= "\"#  Measurement Units:  $units\"\n";
    } else {
        $hdr .= "#  Measurement Units:  $units\n";
    }
    if ($dtype eq "iv") {
        $date_range_sav =~ s/\// to /;
        $hdr .= "#  Statistic:          Instantaneous\n"
              . "#\n"
              . "# Retrieval date range:  $date_range_sav\n";
    } else {
        $dvstat .= "imum" if ($dvstat =~ /Min|Max/);
        $hdr .= "#  Statistic:          Daily $dvstat\n"
              . "#\n"
              . "# Retrieval date range:  $bdate to $edate\n";
    }
    $hdr .= "#\n"
          . "# Header codes:\n";
    if ($dtype eq "iv") {
        $hdr .= "#  Date:       date/time of instantaneous measurement\n";
    } else {
        $hdr .= "#  Date:       date of daily value\n";
    }
    $hdr .= "#  Value:      data value\n"
          . "#  Approval:   approval code (A = approved\; P = provisional)\n"
          . "#  Qualifier:  qualifier code\n"
          . "#\n"
          . "# Data were retrieved by The W2 Animator using USGS Water Data APIs.\n";

  # Determine how much of a time adjustment is needed for subdaily data.
  # Every point may need a date/time adjustment, unless the time zone is
  # not recognized or unless the final time zone is UTC.
    if ($dtype eq "iv") {
        if (defined($utc_offset{$tz_cd})) {
            $add_min += 60 * $utc_offset{$tz_cd};
            if ($tz_off ne "+00:00") {
                $hh = $add_min /60;
                $tz = "UTC" . sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60);
            }
        } else {
            $add_min = 0;
        }
        if (! defined($utc_offset{$tz_cd})) {
            $hdr .= "# All date/time values were kept in UTC (+00:00).\n";
        } elsif ($tz_off ne "+00:00") {
            $hdr .= "# All date/time values were adjusted by $tz_off from local standard time\n"
                  . "# resulting in a final time zone of $tz.\n";
        } else {
            $hdr .= "# All date/time values were adjusted to local standard time:  $tz.\n";
        }
    }
    $hdr .= "#\n";
    $sep  = ($fmt eq "csv") ? "," : "\t";
    $hdr .= "Date" . $sep . "Value" . $sep . "Approval" . $sep . "Qualifier\n";

  # Write header info to the output file
    print $fh $hdr;

  # The qualifier field may have one or more commas that must be modified.
  # Qualifier in the retrieved dataset may look like:
  #   ['ESTIMATED']  or  "['ESTIMATED', 'ICE']"
  # Any such qualifiers will be modified to read:
  #   ESTIMATED   or   ESTIMATED/ICE

  # Case 1:  No time adjustment (daily data, some subdaily data)
    if ($add_min == 0) {
        $msg_txt->configure(-text => "Writing data to file...");
        Tkx::update();
        foreach $line (@lines) {
            $line =~ s/^,,|\s+$//g;
            $line =~ s/Approved/A/;
            $line =~ s/Provisional/P/;
            if ($line =~ /\['/) {
                $line =~ s/', '/\//g;           # substitute / for ', '
                $line =~ s/\[|\]|'|\"//g;       # remove [ ] ' "
            }
            $line =~ s/\+00:00// if ($dtype eq "iv");  # remove +00:00 from date
            $line =~ s/,/\t/g if ($fmt ne "csv");
            print $fh $line, "\n";
        }

  # Case 2:  Time adjustment necessary (subdaily data only)
    } else {
        $msg_txt->configure(-text => "Processing data and writing to file...");
        Tkx::update();
        for ($i=0; $i<=$#lines; $i++) {
            $line = $lines[$i];
            $line =~ s/^,,|\s+$//g;
            $line =~ s/Approved/A/;
            $line =~ s/Provisional/P/;
            $pos  = index($line,",");
            $dt   = substr($line,0,$pos);
            ($sec = $dt) =~ s/^.*(:\d\d)\+00:00$/$1/;
            $dt   =~ s/:\d\d\+00:00$//;
            $dt   = &adjust_date($dt, $add_min);
            $line = substr($line,$pos);
            if ($line =~ /\['/) {
                $line =~ s/', '/\//g;           # substitute / for ', '
                $line =~ s/\[|\]|'|\"//g;       # remove [ ] ' "
            }
            $line =~ s/,/\t/g if ($fmt ne "csv");
            print $fh $dt, $sec, $line, "\n";   # no time zone; see header
        }
    }
    close ($fh);
    $msg_txt->configure(-text => "Done");

    return 1;
}


############################################################################
#
# Subroutine get_USACE_sitelist
#   Use the USACE Corps Water Management System (CWMS) API to return a list
#   of sites and datasets that match user-specified criteria.
#   Also may use the USACE Northwest Division's Dataquery service to add to
#   that list of sites and datasets.
#
#   The primary CWMS search method is by office ID and a regular expression
#   for the site location code. If the office ID is not specified or is "Any"
#   then the search will be only on the site location code. Regular expression
#   wildcards are possible in searching for the site location code.  The
#   following regular expression codes may be used in this search:
#     .  = any one character
#     .* = zero or more characters
#    \.  = the period
#     ^  = beginning of string
#     $  = end of string
#   All CWMS regex matches are case-insensitive.
#   See https://cwms-data.usace.army.mil/cwms-data/regexp.html
#
#   The Dataquery search is simply by a case-insensitive string that could be
#   part of the location code or the site name. The CWMS and Dataquery systems
#   are quite similar, but not exactly the same. The Dataquery system is valid
#   for the following USACE offices:
#     NWD  - Northwestern Division
#     NWDP - Pacific Northwest Region
#     NWP  - Portland District
#     NWS  - Seattle District
#     NWW  - Walla Walla District
#   If one of these office is specified by the user for the CWMS search, or
#   if "Any" office or all offices are searched, then the Dataquery service
#   also will be queried. Dataquery does not allow regular expressions.
#
#   Optional search parameters may include a parameter code or location kind.
#   The location kind can use regex and be part of the original location search.
#   The parameter code filter can only be applied after a list of datasets is
#   obtained.
#
# Information passed to this routine includes:
#   office -- office code, or Any
#   name   -- search term for a location code
#   nmatch -- type of location code search (any, start, end, exact)
#   pcode  -- parameter code
#   lkind  -- location kind code
#   status -- dataset status code (all, active, inactive)
#
#   parent  -- the parent window, used for error messages
#   msg_txt -- name of a label widget for status messages
#
sub get_USACE_sitelist {
    my ($parent, $msg_txt, %args) = @_;
    my (
        $bdate, $byr, $byr1, $ContentLength_hdr, $desc, $drange, $dtype,
        $edate, $eyr, $eyr1, $interval, $jd_diff, $jd_now, $json_data,
        $lcode, $lkind, $msg, $n, $name, $name_DQ, $nmatch, $notes, $nsites,
        $office, $ofname, $ofname2, $parm, $pcode, $ptype, $response,
        $scode, $search_DQ, $setname, $sname, $status, $tm, $try, $tz,
        $tz2, $ua, $url,

        @count, @cwms_sites, @dsets, @lines, @site_codes, @site_data,
        @sites, @vals,

        %datasets, %extents, %results, %site_info,
       );

    $nsites  = 0;
    %results = ();
    $office  = (defined($args{office})) ? $args{office} : "";
    $name    = (defined($args{name}))   ? $args{name}   : "";
    $nmatch  = (defined($args{nmatch})) ? $args{nmatch} : "";
    $pcode   = (defined($args{pcode}))  ? $args{pcode}  : "";
    $lkind   = (defined($args{lkind}))  ? $args{lkind}  : "";
    $status  = (defined($args{status})) ? $args{status} : "";

    if ($office ne "" && &list_match($office, values %cwms_offices) < 0) {
        $office = "";
    }
    if ($pcode ne "" && &list_match($pcode, values %cwms_parameters) < 0) {
        $pcode = "";
    }
    if ($lkind ne "" && &list_match($lkind, @cwms_location_kinds) < 0) {
        $lkind = "";
    }
    $name =~ s/^\s+// if ($nmatch =~ /exact|start/);
    $name =~ s/\s+$// if ($nmatch =~ /exact|end/);
    if ($name eq "" && ($office eq "" || $office eq "CWMS")) {
        return (0) if &pop_up_error($parent, "The search must include an office other\n"
                                           . "than Any or CWMS, and/or at least a partial\n"
                                           . "location code. Please try again.");
    }
    $search_DQ = ($office eq "" || $office =~ /^(NWD|NWDP|NWP|NWS|NWW|CWMS)$/) ? 1 : 0;
    $name_DQ   = $name;
    if ($nmatch eq "any") {
        $name = '.*' . $name . '.*';
    } elsif ($nmatch eq "start") {
        $name = '^' . $name . '.*';
    } elsif ($nmatch eq "end") {
        $name = '.*' . $name . '$';
    } elsif ($nmatch eq "exact") {
        $name = '^' . $name . '$';
    }
    $name_DQ =~ s/[\^\.\*\$\[\]\|]//g;  # Dataquery does not allow regular expressions

  # Construct a URL to obtain a list of locations from the CWMS Data API.
  # A single optional location kind may be included in this search.
    if ($office ne "") {
        $url = 'https://cwms-data.usace.army.mil/cwms-data/catalog/LOCATIONS?office=' . $office
             . '&like=' . uri_escape($name);
    } else {
        $url = 'https://cwms-data.usace.army.mil/cwms-data/catalog/LOCATIONS?like='
             . uri_escape($name);
    }
    if ($lkind ne "") {
        $url .= '&location-kind-like=' . $lkind;
    }
    $url .= '&page-size=5000';

  # Start an LWP client. The LWP::UserAgent version has already been checked.  Older versions
  # of LWP do not recognize the required TLS1.2 security protocols, and old versions also do
  # not recognize the ssl_opts argument.
    $ua = LWP::UserAgent->new(ssl_opts => { SSL_version => 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11' });
    $ua->agent("WebRetriever/0.1 ");
    $ContentLength_hdr = HTTP::Headers->new('Content-Length' => 0,
                                            'Accept'         => 'application/json;version=2');

    $msg_txt->configure(-text => "Searching CWMS for sites... Please wait...");
    Tkx::update();

  # Make a call to the CWMS Data API to get a location list and other site-related metadata.
    $try = 0;
    while (++$try <= 3) {
        $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
        unless ($response->is_success) {
            if ($try < 3) { sleep 1; next; }
            $msg = "ERROR:  Unable to retrieve location\ninformation from the CWMS Data API.";
            @lines = split(/\n/, $response->as_string);
            if ($lines[0] =~ /[4-5][0-9][0-9] /) {
                $lines[0] =~ s/[4-5][0-9][0-9] //;
                $msg .= "\nReason: $lines[0]." if ($lines[0] !~ /404/);
            }
            if (! $search_DQ) {
                return ($nsites, %results) if &pop_up_error($parent, $msg);
            } else {
                &pop_up_error($parent, $msg);
                last;
            }
        }
        $json_data = from_json($response->content);   # not decode_json, already UTF-8

      # JSON data are set up as "entries"
        last if (defined($json_data->{'entries'}));

      # Fail after trying multiple times
        if ($try >= 3 && ! $search_DQ) {
            return ($nsites, %results);
        }
        undef $json_data;
        sleep 1;  # pause for a second, if try failed
    }

  # Parse the location list. Pull out the location code, time zone, public or long name,
  # and site description.
    @site_data = ();
    @site_data = @{ $json_data->{'entries'} } if (defined($json_data));
    if ($#site_data < 0 && ! $search_DQ) {
        return ($nsites, %results);
    }
    for ($n=0; $n<=$#site_data; $n++) {
        next if (! defined($site_data[$n]->{'name'}));
        $tz = $desc = $sname = $ofname = "";
        $lcode  = $site_data[$n]->{'name'};
        $ofname = $site_data[$n]->{'office'}      if (defined($site_data[$n]->{'office'}));
        $tz     = $site_data[$n]->{'time-zone'}   if (defined($site_data[$n]->{'time-zone'}));
        $desc   = $site_data[$n]->{'description'} if (defined($site_data[$n]->{'description'}));
        if (defined($site_data[$n]->{'public-name'})) {
            $sname = $site_data[$n]->{'public-name'};
        } elsif (defined($site_data[$n]->{'long-name'})) {
            $sname = $site_data[$n]->{'long-name'};
        }
        if (&list_match($lcode, keys %results) >= 0) {
            if ($sname ne "" && $ofname ne "" && $tz ne "" &&
                ($results{$lcode}{sname}  eq "" ||
                 $results{$lcode}{office} eq "" ||
                 $results{$lcode}{tz_cd}  eq "")) {
                $nsites--;
            } else {
                next;
            }
        }
        $results{$lcode}{sname}  = $sname;
        $results{$lcode}{office} = $ofname;
        $results{$lcode}{tz_cd}  = $tz;
        $results{$lcode}{desc}   = $desc;
        $nsites++;
    }
    undef $json_data;

  # Now that a list of location codes is in hand, the next step is to find datasets that
  # match user-specified criteria. This second call to the CWMS Data API will obtain
  # dataset IDs as well as starting and ending dates. Data-collection frequency may
  # be provided, but is probably uncertain. Cannot trust the measurement units at
  # this stage of the process. A lot of the site locations found during the first call
  # will not have any datasets from this second call, as a lot of datasets have not
  # been populated in CWMS (yet).
    if ($nsites > 0) {
        if ($office ne "") {
            $url = 'https://cwms-data.usace.army.mil/cwms-data/catalog/TIMESERIES?office=' . $office
                 . '&like=' . uri_escape($name);
        } else {
            $url = 'https://cwms-data.usace.army.mil/cwms-data/catalog/TIMESERIES?like='
                 . uri_escape($name);
        }
        if ($lkind ne "") {
            $url .= '&location-kind-like=' . $lkind;
        }
        $url .= '&page-size=5000';

        $msg_txt->configure(-text => "Searching CWMS for datasets... Please wait...");
        Tkx::update();

      # Make a call to the CWMS Data API to get a dataset list and other dataset-related metadata.
        $try = 0;
        while (++$try <= 3) {
            $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
            unless ($response->is_success) {
                if ($try < 3) { sleep 1; next; }
                $msg = "ERROR:  Unable to retrieve dataset\ninformation from the CWMS Data API.";
                @lines = split(/\n/, $response->as_string);
                if ($lines[0] =~ /[4-5][0-9][0-9] /) {
                    $lines[0] =~ s/[4-5][0-9][0-9] //;
                    $msg .= "\nReason: $lines[0]." if ($lines[0] !~ /404/);
                }
                if (! $search_DQ) {
                    return ($nsites, %results) if &pop_up_error($parent, $msg);
                } else {
                    &pop_up_error($parent, $msg);
                    last;
                }
            }
            $json_data = from_json($response->content);   # not decode_json, already UTF-8

          # JSON data are set up as "entries"
            last if (defined($json_data->{'entries'}));

          # Fail after trying multiple times
            if ($try >= 3 && ! $search_DQ) {
                return ($nsites, %results);
            }
            undef $json_data;
            sleep 1;  # pause for a second, if try failed
        }

      # For a site-status check, get a reference date
        if ($status =~ /^(active|inactive)$/) {
            $tm     = localtime(time);
            $jd_now = &datelabel2jdate($tm->ymd);
        }

      # Parse the dataset list. Pull out the dataset name, time zone, interval,
      # start date, and end date. Add valid information to the site list.
        @dsets = ();
        @dsets = @{ $json_data->{'entries'} } if (defined($json_data));
        if ($#dsets < 0 && ! $search_DQ) {
            $nsites  = 0;
            %results = ();
            return ($nsites, %results);
        }
        @sites = keys %results;
        @count = (0) x @sites;

        for ($n=0; $n<=$#dsets; $n++) {
            next if (! defined($dsets[$n]->{'name'}));
            $setname = $dsets[$n]->{'name'};
            ($lcode, $parm, $ptype, $interval, @vals) = split(/\./, $setname);

            next if (&list_match($lcode, @sites) < 0);
            next if ($pcode ne "" && $parm !~ /$pcode/i);

            next if (! defined($dsets[$n]->{'extents'}));
            %extents = %{ @{ $dsets[$n]->{'extents'} }[0] };
            next if (! defined($extents{'earliest-time'}) ||
                     $extents{'earliest-time'} !~ /^${YYYY_MM_DD_HH_mm_fmt}/);
            next if (! defined($extents{'latest-time'}) ||
                     $extents{'latest-time'} !~ /^${YYYY_MM_DD_HH_mm_fmt}/);

          # May not know the true interval until the datafile is read.
          # For now, assume the interval in the dataset name is meaningful.
            $dtype = ($interval =~ /(day|week|month|year|decade)/i) ? "dv" : "iv";

          # Update the time zone, if necessary.
            $tz = $results{$lcode}{tz_cd};
            if (defined($dsets[$n]->{'time-zone'})) {
                $tz2 = $dsets[$n]->{'time-zone'};
                $tz  = $tz2 if ($tz2 ne "");
            }
            $ofname = $results{$lcode}{office};
            if (defined($dsets[$n]->{'office'})) {
                $ofname2 = $dsets[$n]->{'office'};
                $ofname  = $ofname2 if ($ofname2 ne "");
            }
            $bdate = $extents{'earliest-time'};
            $edate = $extents{'latest-time'};
            if (defined($cwms_utc_offset{$tz})) {
                $bdate = &adjust_date($bdate, $cwms_utc_offset{$tz} *60);
                $edate = &adjust_date($edate, $cwms_utc_offset{$tz} *60);
            }
            $bdate = substr($bdate,0,10);
            $edate = substr($edate,0,10);

          # Check to see if a dataset would be considered active
            if ($status =~ /^(active|inactive)$/) {
                $jd_diff = $jd_now - &datelabel2jdate($edate);
                next if ($status eq "active"   && $jd_diff >  365);
                next if ($status eq "inactive" && $jd_diff <= 365);
            }

            $results{$lcode}{$setname}{date_range} = $bdate . " to " . $edate;
            $results{$lcode}{$setname}{office}     = $ofname;
            $results{$lcode}{$setname}{tz_cd}      = $tz;
            $results{$lcode}{$setname}{pcode}      = $parm;
            $results{$lcode}{$setname}{dtype}      = $dtype;
            $results{$lcode}{$setname}{dbase}      = "CWMS";

            $count[&list_match($lcode, @sites)]++;
        }
    }

  # Remove any results for locations that have no datasets
    if ($nsites > 0) {
        for ($n=0; $n<=$#sites; $n++) {
            if ($count[$n] == 0) {
                delete $results{$sites[$n]};
                $nsites--;
            }
        }
    }
    @cwms_sites = ();
    @cwms_sites = keys %results if ($nsites > 0);

  # Search Dataquery for sites and datasets, if needed
  # Dataquery has two servers:
  #   https://www.nwd-wc.usace.army.mil/dd/common/web_service/webexec/
  #   https://public.crohms.org/dd/common/web_service/webexec/
  # The public.crohms.org server doesn't give me any problems.
  # For www.nwd-wc.usace.army.mil, either the 443 port is not open or there's a bad redirect.
    if ($search_DQ) {
        $url = 'https://public.crohms.org/dd/common/web_service/webexec/getjson?tscatalog='
             . uri_escape('["' . $name_DQ . '"]');

        $msg_txt->configure(-text => "Searching Dataquery for datasets... Please wait...");
        Tkx::update();

      # Make a call to the Dataquery service to get a site and dataset list with metadata.
        $try = 0;
        while (++$try <= 3) {
            $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
            unless ($response->is_success) {
                if ($try < 3) { sleep 1; next; }
                $msg = "ERROR:  Unable to retrieve site\ninformation from Dataquery.";
                @lines = split(/\n/, $response->as_string);
                if ($lines[0] =~ /[4-5][0-9][0-9] /) {
                    $lines[0] =~ s/[4-5][0-9][0-9] //;
                    $msg .= "\nReason: $lines[0]." if ($lines[0] !~ /404/);
                }
                return ($nsites, %results) if &pop_up_error($parent, $msg);
            }
            $json_data  = from_json($response->content);   # not decode_json, already UTF-8
            %site_info  = %{ $json_data };
            @site_codes = keys %site_info;
            last if ($#site_codes >= 0);

          # Fail after trying multiple times
            if ($try >= 3) {
                return ($nsites, %results);
            }
            sleep 1;  # pause for a second, if try failed
        }

      # For a site-status check, get a reference date
        if ($status =~ /^(active|inactive)$/) {
            $tm     = localtime(time);
            $jd_now = &datelabel2jdate($tm->ymd);
        }

      # Parse the site list and keep any sites and datasets that match search criteria,
      # along with appropriate metadata. Dataquery does not provide the location kind.
      # Dataquery also does not provide definitive start and end dates for datasets,
      # just the start and end years. Avoid datasets marked as PRIVATE or Empty.
        for ($n=0; $n<=$#site_codes; $n++) {
            $lcode = $site_codes[$n];
            $sname = $site_info{$lcode}->{'name'} // "";
            if ($nmatch eq "any") {
                next if ($lcode !~ /$name_DQ/i  && $sname !~ /$name_DQ/i);
            } elsif ($nmatch eq "start") {
                next if ($lcode !~ /^$name_DQ/i && $sname !~ /^$name_DQ/i);
            } elsif ($nmatch eq "end") {
                next if ($lcode !~ /$name_DQ$/i && $sname !~ /$name_DQ$/i);
            } elsif ($nmatch eq "exact") {
                next if ($lcode !~ /^$name_DQ$/i && $sname !~ /^$name_DQ$/i);
            }
            $ofname   = $site_info{$lcode}->{'responsibility'} // "";
            $tz       = $site_info{$lcode}->{'timezone'} // "";
            %datasets = %{ $site_info{$lcode}->{'timeseries'} };
            @dsets    = keys %datasets;
            foreach $setname ( @dsets ) {
                ($scode, $parm, $ptype, $interval, @vals) = split(/\./, $setname);
                next if ($scode ne $lcode);
                next if ($pcode ne "" && $parm !~ /$pcode/i);

              # Only the year range is provided by Dataquery, in the notes entry
                $notes = $datasets{$setname}->{'notes'};
                next if ($notes =~ /\(Empty\)|PRIVATE/i);
                next if ($notes !~ /^.*\(\d\d\d\d-\d\d\d\d\).*$/);
                ($byr = $notes) =~ s/^.*\((\d\d\d\d)-\d\d\d\d\).*$/$1/;
                ($eyr = $notes) =~ s/^.*\(\d\d\d\d-(\d\d\d\d)\).*$/$1/;
                $bdate = $byr . '-01-01';
                $edate = $eyr . '-12-31';

              # Check to see if a dataset would be considered active
                if ($status =~ /^(active|inactive)$/) {
                    $jd_diff = $jd_now - &datelabel2jdate($edate);
                    next if ($status eq "active"   && $jd_diff >  365);
                    next if ($status eq "inactive" && $jd_diff <= 365);
                }

              # May not know the true interval until the datafile is read.
              # For now, assume the interval in the dataset name is meaningful.
                $dtype = ($interval =~ /(day|week|month|year|decade)/i) ? "dv" : "iv";

              # If the dataset is already present from the CWMS search,
              # compare the date ranges and keep the longer one.
                if ($#cwms_sites >= 0) {
                    if (&list_match($lcode, @cwms_sites) >= 0) {
                        if (defined($results{$lcode}{$setname})) {
                            $drange = $results{$lcode}{$setname}{date_range};
                            ($byr1 = $drange) =~ s/^(\d\d\d\d)-\d\d-\d\d to .*$/$1/;
                            ($eyr1 = $drange) =~ s/^.* to (\d\d\d\d)-\d\d-\d\d$/$1/;
                            next if ($byr1 <= $byr && $eyr1 >= $eyr);
                            next if ($eyr1 -$byr1 >= $eyr -$byr);
                            delete $results{$lcode}{$setname};
                        }
                    }
                }

              # Save site and dataset info
                if (&list_match($lcode, keys %results) < 0) {
                    $results{$lcode}{sname}  = $sname;
                    $results{$lcode}{office} = $ofname;
                    $results{$lcode}{tz_cd}  = $tz;
                    $nsites++;
                }
                $results{$lcode}{$setname}{date_range} = $byr . " to " . $eyr;
                $results{$lcode}{$setname}{office}     = $ofname;
                $results{$lcode}{$setname}{tz_cd}      = $tz;
                $results{$lcode}{$setname}{pcode}      = $parm;
                $results{$lcode}{$setname}{dtype}      = $dtype;
                $results{$lcode}{$setname}{dbase}      = "Dataquery";
            }
        }
    }

    $msg_txt->configure(-text => "");
    Tkx::update();

  # Return the site information
    return ($nsites, %results);
}


############################################################################
#
# Subroutine get_USACE_dataset
#   Use the USACE Corps Water Management System (CWMS) API or a call to
#   the USACE Dataquery system to return a USACE time-series dataset that
#   matches user-specified criteria.
#
# Information passed to this routine includes:
#   file    -- output file
#   dbase   -- database, either CWMS or Dataquery
#   dset    -- time-series identifier/name
#   office  -- office code
#   site    -- site location code
#   sname   -- site name
#   pcode   -- parameter code
#   pname   -- parameter name
#   dtype   -- code identifying daily (dv) or subdaily (iv) data
#   bdate   -- begin date (YYYY-MM-DD)
#   edate   -- end date (YYYY-MM-DD)
#   tz_cd   -- time zone code (e.g. US/Pacific)
#   tz_off  -- time zone offset (default is +00:00)
#
#   parent  -- the parent window, used for error messages
#   msg_txt -- name of a label widget for status messages
#
sub get_USACE_dataset {
    my ($parent, $msg_txt, %args) = @_;
    my (
        $add_min, $add_min2, $base_url, $bd, $bdate, $bm, $byr, $content,
        $ContentLength_hdr, $d, $date, $date_range, $date1, $dbase, $dfield,
        $done, $dset, $dt, $dtype, $ed, $edate, $em, $eyr, $fh, $file,
        $fmt, $hdr, $hh, $hms, $i, $interval, $item, $json_data, $jd1,
        $jd2, $local_tz, $m, $mm, $msg, $office_id, $office, $pagesize,
        $part, $pcode, $pname, $ptype, $qfield, $response, $sep, $site,
        $sname, $tm, $tm_fmt, $try, $tz, $tz2, $tz_cd, $tz_off, $ua,
        $units, $url, $vfield, $y,

        @bdates, @edates, @tmp, @vals, @values,

        %vcols,
       );

    $file      = (defined($args{file}))   ? $args{file}   : "";
    $dbase     = (defined($args{dbase}))  ? $args{dbase}  : "";
    $dset      = (defined($args{dset}))   ? $args{dset}   : "";
    $office_id = (defined($args{office})) ? $args{office} : "";
    $site      = (defined($args{site}))   ? $args{site}   : "";
    $sname     = (defined($args{sname}))  ? $args{sname}  : "";
    $pcode     = (defined($args{pcode}))  ? $args{pcode}  : "";
    $pname     = (defined($args{pname}))  ? $args{pname}  : "";
    $dtype     = (defined($args{dtype}))  ? $args{dtype}  : "";
    $bdate     = (defined($args{bdate}))  ? $args{bdate}  : "";
    $edate     = (defined($args{edate}))  ? $args{edate}  : "";
    $tz_cd     = (defined($args{tz_cd}))  ? $args{tz_cd}  : "";
    $tz_off    = (defined($args{tz_off})) ? $args{tz_off} : "+00:00";

    $units = $office = "";
    $fmt   = ($file =~ /\.csv$/i) ? "csv" : "tab";
    if ($office_id ne "" && &list_match($office_id, values %cwms_offices) >= 0) {
        foreach $item (keys %cwms_offices) {
            if ($cwms_offices{$item} eq $office_id) {
                $office = $item;
                last;
            }
        }
    }

  # Set the time zone offset.
    if ($dtype eq "dv") {
        $add_min = 0;
    } else {
        if ($tz_off eq "" || $tz_off eq "+00:00" || &list_match($tz_off, @tz_offsets) < 0
                                                 || ! defined($cwms_utc_offset{$tz_cd})) {
            $add_min = 0;
            $tz_off  = "+00:00";
        } else {
            ($hh, $mm) = split(/:/, substr($tz_off,1));
            $add_min   = $hh *60 + $mm;
            $add_min  *= -1 if (substr($tz_off,0,1) eq "-");
        }
    }

  # Construct a partial URL to retrieve the data of interest.
  # For subdaily data retrievals, advance the end date by 1 day.
    if ($dtype eq "iv") {
        $edate = &adjust_dt_by_day($edate, 1);
    }
    if ($dbase eq "CWMS") {
        $base_url  = 'https://cwms-data.usace.army.mil/cwms-data/timeseries?name=' . uri_escape($dset);
        $base_url .= '&office=' . $office_id if ($office_id ne "");
        $base_url .= '&format=json';
    } else {
        $base_url  = 'https://public.crohms.org/dd/common/web_service/webexec/getjson';
    }

  # Date ranges: The begin and end dates should have been passed in YYYY-MM-DD format.
  # For CWMS:
  #  Need to specify the date range in ISO 8601 format (YYYY-MM-DDTHH:mm:ss+HH.MM)
  #  For subdaily data, specify the date range in the local standard time, if possible.
  #  The default maximum number of dates for a data retrieval is 500, which is too short.
  #  For daily values, try chunks of 4000 to 5000, with a limit of 5000.
  #  For subdaily values, try chunks of 365 to 370 days, with a limit of 50000 data points.
  #
    $jd1 = &datelabel2jdate($bdate);
    $jd2 = &datelabel2jdate($edate);
    @bdates = @edates = ();
    if ($dbase eq "CWMS") {
        if (! defined($cwms_utc_offset{$tz_cd}) || $cwms_utc_offset{$tz_cd} == 0) {
            $tz = "Z";
        } else {
            $hh = $cwms_utc_offset{$tz_cd};
            $tz = sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60);
        }
        if ($dtype eq "iv") {
            $date_range = $bdate . 'T00:00:00' . $tz . ' to ' . $edate . 'T00:00:00' . $tz;
            if ($jd2 -$jd1 > 370) {
                $date1 = $bdate;
                while ($jd1 +365 < $jd2) {
                    $date = &jdate2datelabel($jd1 +365, "YYYY-MM-DD");
                    $hms  = ($#bdates >= 0) ? 'T00:00:01' : 'T00:00:00';
                    push (@bdates, $date1 . $hms        . $tz);
                    push (@edates, $date  . 'T00:00:00' . $tz);
                    $jd1  += 365;
                    $date1 = &jdate2datelabel($jd1, "YYYY-MM-DD");
                }
                if ($jd1 < $jd2) {
                    $hms  = ($#bdates >= 0) ? 'T00:00:01' : 'T00:00:00';
                    push (@bdates, $date1 . $hms        . $tz);
                    push (@edates, $edate . 'T00:00:00' . $tz);
                }
            } else {
                push (@bdates, $bdate . 'T00:00:00' . $tz);
                push (@edates, $edate . 'T00:00:00' . $tz);
            }
            $pagesize = 50000;
        } else {
            $date_range = $bdate . " to " . $edate;
            if ($jd2 -$jd1 +1 > 5000) {
                $date1 = $bdate;
                while ($jd1 +4000 < $jd2) {
                    $date = &jdate2datelabel($jd1 +4000, "YYYY-MM-DD");
                    push (@bdates, $date1 . 'T00:00:00' . $tz);
                    push (@edates, $date  . 'T00:00:00' . $tz);
                    $jd1  += 4001;
                    $date1 = &jdate2datelabel($jd1, "YYYY-MM-DD");
                }
                if ($jd1 < $jd2) {
                    push (@bdates, $date1 . 'T00:00:00' . $tz);
                    push (@edates, $edate . 'T00:00:00' . $tz);
                }
            } else {
                push (@bdates, $bdate . 'T00:00:00' . $tz);
                push (@edates, $edate . 'T00:00:00' . $tz);
            }
            $pagesize = 5000;
        }
        $base_url .= '&page-size=' . $pagesize;
        $bdate = shift @bdates;
        $edate = shift @edates;
        $url   = $base_url . '&begin=' . uri_escape($bdate) . '&end=' . uri_escape($edate);

  # For Dataquery:
  #  Dates in the URL are expected specified in MM/DD/YYYY+TZ:TZ format
  #  where the time zone corresponds to the zone specified in the URL.
  #  So, start and end dates should be specified as MM/DD/YYYY+00:00.
  #  No data-count limits have been encountered, but the retrievals for
  #  subdaily data will be limited to 2-year periods.
  #
    } else {
        if (defined($cwms_utc_offset{$tz_cd})) {
            $base_url .= '?timezone=' . $tz_cd;
            $hh  = $cwms_utc_offset{$tz_cd};
            $tz2 = sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60);
        } else {
            $url .= '?timezone=GMT';
            $tz2 = '+00:00';
        }
        $tz = '+00:00';
        ($byr, $bm, $bd) = split(/-/, $bdate);
        ($eyr, $em, $ed) = split(/-/, $edate);
        if ($dtype eq "iv") {
            $date_range = $bdate . 'T00:00:00' . $tz2 . ' to ' . $edate . 'T00:00:00' . $tz2;
            if ($jd2 -$jd1 > 740) {
                while ($jd1 +735 < $jd2) {
                    push (@bdates, sprintf("%02d/%02d/%04d", $bm, $bd, $byr)   . $tz);
                    push (@edates, sprintf("%02d/%02d/%04d", $bm, $bd, $byr+2) . $tz);
                    $byr +=2;
                    $jd1 = &date2jdate(sprintf("%04d%02d%02d", $byr, $bm, $bd));
                }
                if ($jd1 < $jd2) {
                    push (@bdates, sprintf("%02d/%02d/%04d", $bm, $bd, $byr) . $tz);
                    push (@edates, sprintf("%02d/%02d/%04d", $em, $ed, $eyr) . $tz);
                }
            } else {
                push (@bdates, sprintf("%02d/%02d/%04d", $bm, $bd, $byr) . $tz);
                push (@edates, sprintf("%02d/%02d/%04d", $em, $ed, $eyr) . $tz);
            }
        } else {
            $date_range = $bdate . ' to ' . $edate;
            push (@bdates, sprintf("%02d/%02d/%04d", $bm, $bd, $byr) . $tz);
            push (@edates, sprintf("%02d/%02d/%04d", $em, $ed, $eyr) . $tz);
        }
        $bdate = shift @bdates;
        $edate = shift @edates;
        $base_url .= '&query=' . uri_escape('["' . $dset . '"]');
        $url = $base_url . '&startdate=' . uri_escape($bdate, "^0-9\-+")
                         . '&enddate='   . uri_escape($edate, "^0-9\-+");  # don't encode the +
    }

  # Start an LWP client. The LWP::UserAgent version has already been checked.  Older versions
  # of LWP do not recognize the required TLS1.2 security protocols, and old versions also do
  # not recognize the ssl_opts argument.
    $ua = LWP::UserAgent->new(ssl_opts => { SSL_version => 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11' });
    $ua->agent("WebRetriever/0.1 ");
    $ContentLength_hdr = HTTP::Headers->new('Content-Length'  => 0,
                                            'Accept-Encoding' => 'gzip, deflate');

  # Try to retrieve the dataset.
  # Iterate until all data are retrieved. More than one call may be required, given that
  # the retrievals may be limited to certain date ranges or a maximum number of data points.
    $msg_txt->configure(-text => "Requesting data... Please wait...");
    Tkx::update();

    $part   = 1;
    $dfield = 0;
    $vfield = 1;
    $qfield = 2;
    @values = @vals = @tmp = ();
    $done   = 0;
    until ($done) {
        $try = 0;
        while (++$try <= 3) {
            $response = $ua->request(HTTP::Request->new(GET => $url, $ContentLength_hdr));
            unless ($response->is_success) {
                if ($try < 3) { sleep 1; next; }
                if ($dbase eq "CWMS") {
                    $msg = "ERROR:  Unable to retrieve\ndata from the CWMS Data API.";
                } else {
                    $msg = "ERROR:  Unable to retrieve data from Dataquery.";
                }
                @tmp = split(/\n/, $response->as_string);
                if ($tmp[0] =~ /[4-5][0-9][0-9] /) {
                    $tmp[0] =~ s/[4-5][0-9][0-9] //;
                    $msg .= "\nReason: $tmp[0]." if ($tmp[0] !~ /404/);
                }
                undef @vals;
                undef @values;
                return 0 if &pop_up_error($parent, $msg);
            }
            $content = $response->decoded_content;
            if ($dbase eq "Dataquery" && $content =~ /\{\"Error\":\"Invalid Request\"\}/) {
                $content =~ s/\{\"Error\":\"Invalid Request\"\}//;
            }
            $json_data = from_json($content);  # not decode_json, already UTF-8

          # Certain fields are expected in the response
            if ($dbase eq "CWMS") {
                if (defined($json_data->{'values'}) && defined($json_data->{'value-columns'})) {
                    if ($part == 1) {
                        @tmp = @{ $json_data->{'value-columns'} };
                        for ($i=0; $i<=$#tmp; $i++) {
                            %vcols = %{ $tmp[$i] };
                            if ($vcols{name} eq "date-time") {
                                $dfield = $vcols{ordinal} -1;
                            } elsif ($vcols{name} eq "value") {
                                $vfield = $vcols{ordinal} -1;;
                            } elsif ($vcols{name} eq "quality-code") {
                                $qfield = $vcols{ordinal} -1;;
                            }
                        }
                    }
                    last;
                }

          # Dataquery output does not define the values fields. Use defaults.
            } else {
                last if (defined($json_data->{$site}) &&
                         defined($json_data->{$site}->{'timeseries'}) &&
                         defined($json_data->{$site}->{'timeseries'}->{$dset}) &&
                         defined($json_data->{$site}->{'timeseries'}->{$dset}->{'values'}));
            }

          # Fail after trying multiple times
            if ($try >= 3) {
                undef @vals;
                undef @values;
                return 0;
            }
            sleep 1;  # pause for a second, if try failed
        }

      # Add recent data to the master array
        if ($dbase eq "CWMS") {
            @vals = @{ $json_data->{'values'} };
            push (@values, @vals);
            undef @vals;

          # Check to see if another request is needed to get the next chunk of data.
          # The 'total' field should denote the number of data points in the full retrieval.
          # If the total is more than the page size, then an unscheduled call is needed.
            if (defined($json_data->{'total'}) && $json_data->{'total'} > $pagesize) {
                $tm = gmtime($values[$#values][$dfield] /1000);
                if ($dtype eq "iv") {
                    $tm++                       # add one second
                } else {
                    $tm += 86400;               # add one day
                }
                $bdate = $tm->datetime . 'Z';   # fmt: YYYY-MM-DDTHH:mm:ss
            } else {
                if ($#bdates >= 0) {
                    $bdate = shift @bdates;
                    $edate = shift @edates;
                } else {
                    $done = 1;
                }
            }
            if (! $done) {
                $url = $base_url . '&begin=' . uri_escape($bdate) . '&end=' . uri_escape($edate);
            }

        } else {
            @vals = @{ $json_data->{$site}->{'timeseries'}->{$dset}->{'values'} };
            if ($part > 1) {
                if ($vals[0][$dfield] eq $values[$#values][$dfield]) {
                    shift @vals;
                }
            }
            push (@values, @vals);
            undef @vals;
            if ($#bdates >= 0) {
                $bdate = shift @bdates;
                $edate = shift @edates;
                $url = $base_url . '&startdate=' . uri_escape($bdate, "^0-9\-+")
                                 . '&enddate='   . uri_escape($edate, "^0-9\-+");
            } else {
                $done = 1;
            }
        }
        if (! $done) {
            $part++;
            $msg_txt->configure(-text => "Requesting data, part $part... Please wait...");
            Tkx::update();
        }
    }

  # Open the output file
    $msg_txt->configure(-text => "Opening output file...");
    Tkx::update();
    open ($fh, ">$file") or ((return 0) && &pop_up_error($parent, "Unable to open output file:\n$file."));

  # Create a header that conforms to the chosen format and provides useful information.
    $tm       = localtime(time);
    $local_tz = $tm->strftime("%z");
    $local_tz = "UTC" . substr($local_tz,0,-2) . ":" . substr($local_tz,-2) if ($local_tz !~ /:/);
    $date     = $tm->ymd . " " . $tm->hms . "  TZ: " . $local_tz;

    $hdr = "# -------------------- USACE Corps Water Management System --------------------\n"
         . "# The Corps Water Management System (CWMS) Data API allows public access to\n"
         . "# current and historical time-series datasets collected by or for the U.S. Army\n"
         . "# Corps of Engineers. Data downloaded from CWMS are considered preliminary, are\n"
         . "# subject to change, and should not be used for critical purposes.\n"
         . "#\n";
    if ($dbase eq "CWMS") {
        $units = $json_data->{'units'} if (defined($json_data->{'units'}));
        $hdr .= "# Retrieval Info: https://github.com/USACE/cwms-data-api/wiki\n"
              . "# Documentation:  https://cwms-data-api.readthedocs.io/latest/\n";
    } else {
        $units  = $json_data->{$site}->{'timeseries'}->{$dset}->{'units'} // "";
        $tm_fmt = $json_data->{$site}->{'time_format'} // '%Y-%m-%dT%H:%M:%S%z';
        $tm_fmt =~ s/\%z//;
        $hdr .= "# This dataset was retrieved from the USACE Dataquery system.\n"
              . "# Retrieval Info: https://public.crohms.org/dd/common/dataquery/www/\n";
    }
    $hdr .= "# Retrieved:      $date\n"
          . "#\n"
          . "# Data in this file are from the following site:\n";

    if ($fmt eq "csv" && $site =~ /,/) {
        $hdr .= "\"#  Location code:  $site\"\n";
    } else {
        $hdr .= "#  Location code:  $site\n";
    }
    if ($fmt eq "csv" && $sname =~ /,/) {
        $hdr .= "\"#  Site Name:      $sname\"\n";
    } else {
        $hdr .= "#  Site Name:      $sname\n";
    }
    $hdr .= "#  Office:         " . $office_id . ": " . $office . "\n" if ($office_id ne "");

    if (defined($cwms_utc_offset{$tz_cd})) {
        $hh = $cwms_utc_offset{$tz_cd};
        $tz = $tz_cd . " (UTC" . sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60) . ")";
    } else {
        $tz = $tz_cd;
    }
    $hdr .= "#  Time Zone:      $tz\n"
          . "#\n"
          . "# The dataset represents a specific time series:\n";

    if ($fmt eq "csv" && $dset =~ /,/) {
        $hdr .= "\"#  Time Series ID:     $dset\"\n";
    } else {
        $hdr .= "#  Time Series ID:     $dset\n";
    }
    if ($fmt eq "csv" && $pcode =~ /,/) {
        $hdr .= "\"#  Parameter Code:     $pcode\"\n";
    } else {
        $hdr .= "#  Parameter Code:     $pcode\n";
    }
    if ($fmt eq "csv" && $pname =~ /,/) {
        $hdr .= "\"#  Parameter Name:     $pname\"\n";
    } else {
        $hdr .= "#  Parameter Name:     $pname\n";
    }
    if ($fmt eq "csv" && $units =~ /,/) {
        $hdr .= "\"#  Measurement Units:  $units\"\n";
    } else {
        $hdr .= "#  Measurement Units:  $units\n";
    }

    (undef, undef, $ptype, $interval, @vals) = split(/\./, $dset);
    if ($ptype =~ /Min|Max/) {
        $ptype .= "imum";
    } elsif ($ptype eq "Const") {
        $ptype = "Constant";
    } elsif ($ptype eq "Ave") {
        $ptype = "Average";
    } elsif ($ptype eq "Inst") {
        $ptype = "Instantaneous";
    }
    $interval = "Irregular (0)" if ($interval eq "0");
    $hdr .= "#  Parameter Type:     $ptype\n"
          . "#  Data Interval:      $interval\n"
          . "#\n"
          . "# Retrieval date range:  $date_range\n"
          . "#\n"
          . "# Header codes:\n";
    if ($dtype eq "iv") {
        $hdr .= "#  Date:       date/time of measurement\n";
    } else {
        $hdr .= "#  Date:       date of value\n";
    }
    $hdr .= "#  Value:      data value\n"
          . "#  Qualifier:  qualifier code (0 = not screened)\n"
          . "#\n";
    if ($dbase eq "CWMS") {
        $hdr .= "# Data were retrieved by The W2 Animator using the CWMS Data API.\n";
    } else {
        $hdr .= "# Data were retrieved by The W2 Animator using the Dataquery service.\n";
    }

  # Determine how much of a time adjustment is needed for subdaily data.
  # Note that CWMS data retrievals return date/times in UTC, whereas Dataquery retrievals
  # return date/times in the stated time zone (often PST, MST, or GMT).
    if ($dtype eq "iv") {
        if (defined($cwms_utc_offset{$tz_cd})) {
            $add_min2 = $add_min +60 * $cwms_utc_offset{$tz_cd};
            if ($tz_off ne "+00:00") {
                $hh = $add_min2 /60;
                $tz = "UTC" . sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60);
            }
        } else {
            $add_min = $add_min2 = 0;
        }
        if ($dbase eq "CWMS") {
            $add_min = $add_min2;
            if (! defined($cwms_utc_offset{$tz_cd})) {
                $hdr .= "# All date/time values were kept in UTC (+00:00).\n";
            } elsif ($tz_off ne "+00:00") {
                $hdr .= "# All date/time values were adjusted by $tz_off from the site\'s assigned\n"
                      . "# time zone, resulting in a final time zone of $tz.\n";
            } else {
                $hdr .= "# All date/time values were adjusted to the site\'s assigned time zone:\n"
                      . "#   $tz.\n";
            }
        } else {
            if (! defined($cwms_utc_offset{$tz_cd})) {
                $hdr .= "# All date/time values were kept in time zone $tz_cd.\n";
            } elsif ($tz_off ne "+00:00") {
                $hdr .= "# All date/time values were adjusted by $tz_off from the site\'s assigned\n"
                      . "# time zone, resulting in a final time zone of $tz.\n";
            } else {
                $hdr .= "# All date/time values were kept in the site\'s assigned time zone:\n"
                      . "#   $tz.\n";
            }
        }
    }
    $hdr .= "#\n";
    $sep  = ($fmt eq "csv") ? "," : "\t";
    $hdr .= "Date" . $sep . "Value" . $sep . "Qualifier\n";

  # Write header info to the output file
    print $fh $hdr;

  # Note that CWMS data retrievals return dates in java.sql.timestamps, which is the
  # number of milliseconds since January 1, 1970 at 00:00:00 GMT, and all retrieved
  # dates are relative to UTC.
  # In contrast, Dataquery retrievals return dates in YYYY-MM-DDTHH:mm:ss format and
  # for the requested time zone. That time zone may not be correct for the site of
  # interest, but that can't be helped. Actually, the date/time format could be
  # different, but the output file specifies the format.

  # Case 1:  No time adjustment (daily data, some subdaily data)
    if ($add_min == 0) {
        $msg_txt->configure(-text => "Writing data to file...");
        Tkx::update();
        if ($dbase eq "CWMS") {
            for ($i=0; $i<=$#values; $i++) {
                $tm = gmtime($values[$i][$dfield] /1000);
                if ($dtype eq "dv") {
                    $dt = $tm->ymd;
                } else {
                    $dt = $tm->ymd . " " . $tm->hms;
                }
                print $fh $dt, $sep, $values[$i][$vfield] // '', $sep, $values[$i][$qfield] // '', "\n";
            }
        } else {
            for ($i=0; $i<=$#values; $i++) {
                $dt = $values[$i][$dfield];
                if ($dtype eq "dv") {
                    $dt =~ s/T.*$//;
                } else {
                    $dt =~ s/T/ /;
                }
                print $fh $dt, $sep, $values[$i][$vfield] // '', $sep, $values[$i][$qfield] // '', "\n";
            }
        }

  # Case 2:  Time adjustment necessary (subdaily data only)
    } else {
        $msg_txt->configure(-text => "Processing data and writing to file...");
        Tkx::update();
        if ($dbase eq "CWMS") {
            for ($i=0; $i<=$#values; $i++) {
                $tm  = gmtime($values[$i][$dfield] /1000);
                $tm += $add_min *60;
                $dt  = $tm->ymd . " " . $tm->hms;
                print $fh $dt, $sep, $values[$i][$vfield] // '', $sep, $values[$i][$qfield] // '', "\n";
            }
        } else {
            for ($i=0; $i<=$#values; $i++) {
                $dt  = $values[$i][$dfield];
                $tm  = Time::Piece->strptime($dt, $tm_fmt);
                $tm += $add_min *60;
                $dt  = $tm->ymd . " " . $tm->hms;
                print $fh $dt, $sep, $values[$i][$vfield] // '', $sep, $values[$i][$qfield] // '', "\n";
            }
        }
    }

    close ($fh);
    $msg_txt->configure(-text => "Done");

    return 1;
}


1;
