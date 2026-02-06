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

#
# Load important modules
#  LWP -- the World Wide Web library library for Perl
#  LWP::Protocol::https -- to handle https requests
#  LWP::UserAgent and Compress::Zlib may get loaded automatically
#  URI::Escape -- to encode special characters for use in URLs
#  Text::CSV -- to parse csv text that contain commas in a quoted field
#
use strict;
use warnings;
use diagnostics;
use LWP;
use LWP::Protocol::https;
use POSIX 'strftime';
use URI::Escape;
use Text::CSV;

#
# Shared global variables
#
our (
     $LWP_OK,
     @tz_offsets, @usgs_pcodes,
     %huc_region, %huc_subregion, %huc_units, %site_type_codes, %state_code,
     %utc_offset,
    );

#
# Local variables
#
my (
    $LWP_UA_ver, $YYYY_MM_DD_fmt, $YYYY_MM_DD_HH_mm_fmt,
    %dst_pairs,
   );

$YYYY_MM_DD_fmt       = "[12][0-9][0-9][0-9]-[01]?[0-9]-[0-3]?[0-9]";
$YYYY_MM_DD_HH_mm_fmt = "[12][0-9][0-9][0-9]-[01]?[0-9]-[0-3]?[0-9][ T][012]?[0-9]:[0-5][0-9]";

#
# Check the LWP::UserAgent version, because older versions of LWP do not
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

#
# The following is a list of time zones that may now or in the past implemented
# a daylight saving time. The standard time zone name is listed first, followed by
# the daylight saving time name.  Not currently used.
# See: https://api.waterdata.usgs.gov/ogcapi/v0/collections/time-zone-codes/items
#
# All of these time zones implement (or did implement) a 1-hour time difference
# between daylight saving time and standard time, except for LHST/LHDT. For
# Lord Howe Island (New South Wales, Australia), the difference is only 30 minutes.
#
%dst_pairs = ("AKST", "AKDT",   # Alaska Standard Time, Alaska Daylight Time
              "AST",  "ADT",    # Atlantic Standard Time, Atlantic Daylight Time
              "AWST", "AWDT",   # Australian Western Standard Time, Australian Western Daylight Time
              "CET",  "CEST",   # Central European Time, Central European Summer Time
              "CST",  "CDT",    # Central Standard Time, Central Daylight Time (USA)
              "DNT",  "DST",    # Dansk Normal Time, Dansk Summer Time
              "EET",  "EEST",   # Eastern European Time, Eastern European Summer Time
              "EST",  "EDT",    # Eastern Standard Time, Eastern Daylight Time (USA)
              "GMT",  "BST",    # Greenwich Mean Time, British Summer Time
              "HST",  "HDT",    # Hawaii Standard Time, Hawaii-Aleutian Daylight Time
              "MST",  "MDT",    # Mountain Standard Time, Mountain Daylight Time (USA)
              "NST",  "NDT",    # Newfoundland Standard Time, Newfoundland Time
              "NZST", "NZDT",   # New Zealand Standard Time, New Zealand Daylight Time
              "PST",  "PDT",    # Pacific Standard Time, Pacific Daylight Time (USA)
              "SAT",  "SADT",   # Southern Australia Time, Southern Australia Daylight Time
              "ACST", "ACDT",   # Australian Central Standard Time, Australian Central Daylight Time
              "AEST", "AEDT",   # Australian Eastern Standard Time, Australian Eastern Daylight Time
              "CAST", "CADT",   # Central Australia Standard Time, Central Australia Daylight Time
              "FWT",  "FST",    # French Winter Time, French Summer Time
              "IST",  "IDT",    # Israel Standard Time, Israel Daylight Time
              "IRST", "IRDT",   # Iran Standard Time, Iran Daylight Time
              "MEWT", "MEST",   # Middle Europe Winter Time, Middle Europe Summer Time
              "WET",  "WEST",   # Western European Time, Western European Summer Time
              "SWT",  "SST",    # Swedish Standard Time, Swedish Summer Time
              "LHST", "LHDT",   # Lord Howe Standard Time, Lord Howe Daylight Time
             );

#
# A list of time zone codes likely to be in USGS National Water Information System.
# This is not a complete list, but it focuses on the time zone abbreviations known
# to be used in all NWIS site files as of 2017.  Some may no longer be used.
# See: https://api.waterdata.usgs.gov/ogcapi/v0/collections/time-zone-codes/items
#
# The offset value is the number of hours that makes the time zone different from UTC.
# If a user asks to perform a time zone offset, the new time zone listed in the data
# file will be UTC +/- HH:MM.
#
%utc_offset = (AFT    =>   4.5,   # Afghanistan Time
               AKST   =>  -9.0,   # Alaska Standard Time
               AKDT   =>  -8.0,   # Alaska Daylight Time
               AST    =>  -4.0,   # Atlantic Standard Time
               ADT    =>  -3.0,   # Atlantic Daylight Time
               AWST   =>   8.0,   # Australian Western Standard Time
               AWDT   =>   9.0,   # Australian Western Daylight Time
               BT     =>   3.0,   # Baghdad Time
               CET    =>   1.0,   # Central European Time
               CEST   =>   2.0,   # Central European Summer Time
               CST    =>  -6.0,   # Central Standard Time (USA)
               CDT    =>  -5.0,   # Central Daylight Time (USA)
               DST    =>   1.0,   # Dansk Summer Time
               EET    =>   2.0,   # Eastern European Time
               EEST   =>   3.0,   # Eastern European Summer Time
               EST    =>  -5.0,   # Eastern Standard Time (USA)
               EDT    =>  -4.0,   # Eastern Daylight Time (USA)
               GMT    =>   0.0,   # Greenwich Mean Time
               BST    =>   1.0,   # British Summer Time
               GST    =>  10.0,   # Guam Standard Time
               CHST   =>  10.0,   # Chamorro Standard Time
               HST    => -10.0,   # Hawaii Standard Time
               HDT    =>  -9.0,   # Hawaii-Aleutian Daylight Time
               IDLE   =>  12.0,   # International Date Line, East
               IDLW   => -12.0,   # International Date Line, West
               JST    =>   9.0,   # Japan Standard Time
               MST    =>  -7.0,   # Mountain Standard Time (USA)
               MDT    =>  -6.0,   # Mountain Daylight Time (USA)
               NST    =>  -3.5,   # Newfoundland Standard Time
               NDT    =>  -2.5,   # Newfoundland Daylight Time
               NZT    =>  12.0,   # New Zealand Time
               NZST   =>  12.0,   # New Zealand Standard Time
               NZDT   =>  13.0,   # New Zealand Daylight Time
               PST    =>  -8.0,   # Pacific Standard Time (USA)
               PDT    =>  -7.0,   # Pacific Daylight Time (USA)
               SAT    =>   9.5,   # Southern Australia Time
               SADT   =>  10.5,   # Southern Australia Daylight Time
               ACST   =>   9.5,   # Australian Central Standard Time
               ACDT   =>  10.5,   # Australian Central Daylight Time
               UTC    =>   0.0,   # Universal Coordinated Time
               WAST   =>   8.0,   # Western Australia Standard Time
               WAT    =>   1.0,   # West Africa Time
               ZP11   =>  11.0,   # no common name
               ZP4    =>   4.0,   # no common name
               ZP5    =>   5.0,   # no common name
               ZP6    =>   6.0,   # no common name
              'ZP-11' => -11.0,   # no common name
              'ZP-2'  =>  -2.0,   # no common name
              'ZP-3'  =>  -3.0,   # no common name

# This second group of codes may not be in use in NWIS. Added for fun. Not all codes
# listed at the link below were accurate.
# See: https://api.waterdata.usgs.gov/ogcapi/v0/collections/time-zone-codes/items

               AEST   =>  10.0,   # Australian Eastern Standard Time
               AEDT   =>  11.0,   # Australian Eastern Daylight Time
               CAST   =>   9.5,   # Central Australia Standard Time
               CADT   =>  10.5,   # Central Australia Daylight Time
               CCT    =>   8.0,   # China Coastal Time
               DNT    =>   1.0,   # Dansk Normal Time
               EAST   =>  10.0,   # East Australian Standard Time
               FWT    =>   0.0,   # French Winter Time
               FST    =>   1.0,   # French Summer Time
               IST    =>   2.0,   # Israel Standard Time
               IDT    =>   3.0,   # Israel Daylight Time
               IT     =>   3.5,   # Iran Time
               IRST   =>   3.5,   # Iran Standard Time
               IRDT   =>   3.5,   # Iran Daylight Time
               JT     =>   7.0,   # Java Time
               KST    =>   9.0,   # Korea Standard Time
               LIGT   =>  10.0,   # Melbourne Australia Time
               MET    =>   1.0,   # Middle Europe Time
               MEWT   =>   1.0,   # Middle Europe Winter Time
               MEST   =>   2.0,   # Middle Europe Summer Time
               MEZ    =>   1.0,   # Middle Europe Zone
               NFT    =>  -3.5,   # Newfoundland Standard Time
               NOR    =>   1.0,   # Norway Standard Time
               SET    =>   1.0,   # Seychelles Time
               SWT    =>   1.0,   # Swedish Standard Time
               SST    =>   2.0,   # Swedish Summer Time
               WET    =>   0.0,   # Western Europe Time
               WEST   =>   1.0,   # Western Europe Summer Time
               LHST   =>  10.5,   # Lord Howe Standard Time
               LHDT   =>  11.0,   # Lord Howe Daylight Time
              );


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
#   is due to be retired in the first quarter of 2027.
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
#   parent  -- the parent window, used for error messages
#
sub get_USGS_sitelist {
    my ($parent, %args) = @_;
    my (
        $agcy_field, $bdate, $bdate_field, $code, $ContentLength_hdr,
        $csv, $d, $date, $dataset, $dtype, $dvstat, $edate, $edate_field,
        $filter, $filter1, $filter2, $filter3, $found_huc8, $huc, $huc6, $i,
        $id_field, $idmatch, $indx, $jd_diff, $jd_now, $len, $m, $method,
        $msg, $name, $name2, $name3, $name_field, $nmatch, $nsites, $pcode,
        $pcode_field, $pname_field, $response, $site, $site_field, $sitelist,
        $status, $stat, $stat_field, $stype, $sublc_field, $try, $tz_cd,
        $tz_field, $ua, $units_field, $url, $wild1, $wild2, $y,

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

            $filter3 = uri_escape("monitoring_location_name LIKE '$wild1") . $name . uri_escape("$wild2'");
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

  # Start an LWP client.
  # Don't try to verify the host name, as that might lead to SSL certificate-checking errors.
  # The LWP::UserAgent version has already been checked.  Older versions of LWP do not
  # recognize the required TLS1.2 security protocols, and old versions also do not recognize
  # the ssl_opts argument.
    $ua = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0,
                                           SSL_version     => 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11',
                                          });
    $ua->agent("WebRetriever/0.1 ");
    $ContentLength_hdr = HTTP::Headers->new('Content-Length' => 0);

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
        $results{$site}{agency}  = $vals[$agcy_field];
        $results{$site}{name}    = $vals[$name_field];
        $results{$site}{tz_cd}   = $vals[$tz_field];
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

      # For a status check, get a reference date
        if ($status =~ /^(active|inactive)$/) {
            (undef,undef,undef,$d,$m,$y,undef,undef,undef) = localtime(time);
            $date   = sprintf("%04d-%02d-%02d", $y+1900, $m+1, $d);
            $jd_now = &datelabel2jdate($date);
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
            next if (! defined($vals[$bdate_field]) || $vals[$edate_field] !~ /^${YYYY_MM_DD_HH_mm_fmt}/);

          # Convert begin and end dates to local time
            $tz_cd = $results{$site}{tz_cd};
            $bdate = $vals[$bdate_field];
            $edate = $vals[$edate_field];
            if (defined($utc_offset{$tz_cd})) {
                $bdate = &adjust_date($vals[$bdate_field], $utc_offset{$tz_cd} *60);
                $edate = &adjust_date($vals[$edate_field], $utc_offset{$tz_cd} *60);
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
        $add_min, $agency, $base_url, $bdate, $ContentLength_hdr, $d,
        $date, $date1, $date_range, $done, $dt, $dtype, $dvstat, $edate,
        $fh, $file, $fmt, $h, $hdr, $hh, $hrs, $i, $jd1, $jd2, $last_date,
        $line, $local_tz, $m, $mi, $mm, $msg, $offset, $part, $pcode, $pname,
        $pos, $response, $sec, $sep, $site, $site_id, $site_no, $sname,
        $subloc, $try, $ts_id, $tz, $tz_cd, $tz_off, $ua, $units, $url, $y,

        @date_ranges, @lines, @tmp,
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
    $base_url .= '&lang=en-US&limit=50000&skipGeometry=true'
               . '&properties=time,value,approval_status,qualifier'
               . '&time_series_id=' . $ts_id;

  # Need to specify the date range in RFC 3339 format (YYYY-MM-DDTHH:mm:ss.sss+HH.MM)
  # The begin and end dates should have been passed in YYYY-MM-DD format.
  # For subdaily data, specify the date range in the local standard time.
  # For daily data, it should be okay to specify dates as YYYY-MM-DD only.
    if ($dtype eq "iv") {
        if (defined($utc_offset{$tz_cd})) {
            $hh = $utc_offset{$tz_cd};
            if ($hh == 0.) {
                $date_range = $bdate . 'T00:00:00Z/' . $edate . 'T00:00:00Z';
            } else {
                $tz = sprintf("%+03d:%02d", int($hh), abs($hh -int($hh)) *60);
                $date_range = $bdate . 'T00:00:00' . $tz . '/' . $edate . 'T00:00:00' . $tz;
            }
        } else {
            $date_range = $bdate . 'T00:00:00Z/' . $edate . 'T00:00:00Z';
        }
        $base_url .= '&datetime=' . uri_escape($date_range);
        $url = $base_url . '&offset=0';
    } else {
        $jd1 = &datelabel2jdate($bdate);
        $jd2 = &datelabel2jdate($edate);
        @date_ranges = ();
        if ($jd2 -$jd1 +1 > 50000) {
            $date1 = $bdate;
            while ($jd1 +40000 < $jd2) {
                $date = &jdate2datelabel($jd1 +40000, "YYYY-MM-DD");
                $date_range = $date1 . 'T00:00:00Z/' . $date . 'T00:00:00Z';
                push (@date_ranges, $date_range);
                $jd1  += 40001;
                $date1 = &jdate2datelabel($jd1, "YYYY-MM-DD");
            }
            if ($jd1 <= $jd2) {
                $date_range = $date1 . 'T00:00:00Z/' . $edate . 'T00:00:00Z';
                push (@date_ranges, $date_range);
            }
        } else {
            $date_range = $bdate . 'T00:00:00Z/' . $edate . 'T00:00:00Z';
            push (@date_ranges, $date_range);
        }
        $date_range = shift @date_ranges;
        $base_url  .= '&sortby=time' . '&offset=0';
        $url = $base_url . '&datetime=' . uri_escape($date_range);
    }

  # Start an LWP client.
  # Don't try to verify the host name, as that might lead to SSL certificate-checking errors.
  # The LWP::UserAgent version has already been checked.  Older versions of LWP do not
  # recognize the required TLS1.2 security protocols, and old versions also do not recognize
  # the ssl_opts argument.
    $ua = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0,
                                           SSL_version     => 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11',
                                          });
    $ua->agent("WebRetriever/0.1 ");
    $ContentLength_hdr = HTTP::Headers->new('Content-Length' => 0, 'Accept-Encoding' => 'gzip, deflate');

  # Try to retrieve the dataset.
  # Iterate until all data are retrieved. It may take more than one call, given that
  # the retrievals are limited to 50,000 data points at a time.
    $msg_txt->configure(-text => "Requesting data... Please wait...");
    Tkx::update();

    $part  = 1;
    @lines = @tmp = ();
    $done  = $offset = 0;
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

      # If the subdaily request returned 50001 lines, another retrieval may be needed.
        if ($dtype eq "iv") {
            if ($#tmp == 50000) {
                ($line = $tmp[$#tmp]) =~ s/\s+$//;
                ($last_date = $line) =~ s/^.*(${YYYY_MM_DD_fmt}).*$/$1/;
                if ($last_date ge $edate) {
                    $done = 1;
                } else {
                    $offset += 50000;
                    $url = $base_url . '&offset=' . $offset;
                    $part++;
                    $msg_txt->configure(-text => "Requesting data, part $part... Please wait...");
                    Tkx::update();
                }
            } else {
                $done = 1;
            }

      # For daily data, may need to specify another date range and ask for more data.
        } else {
            if ($#date_ranges >= 0) {
                $date_range = shift @date_ranges;
                $url = $base_url . '&datetime=' . uri_escape($date_range);
                $part++;
                $msg_txt->configure(-text => "Requesting data, part $part... Please wait...");
                Tkx::update();
            } else {
                $done = 1;
            }
        }
        shift @tmp;
        push (@lines, @tmp);
        undef @tmp;
    }

  # Open the output file
    $msg_txt->configure(-text => "Opening output file...");
    Tkx::update();
    open ($fh, ">$file") or ((return 0) && &pop_up_error($parent, "Unable to open output file:\n$file."));

  # Create a header that conforms to the chosen format, provides useful information,
  # and looks somewhat like the old default format from USGS Water Services.
    ($sec,$mi,$h,$d,$m,$y,undef,undef,undef) = localtime(time);
    $local_tz = strftime("%z", localtime());
    $local_tz = "UTC" . substr($local_tz,0,-2) . ":" . substr($local_tz,-2) if ($local_tz !~ /:/);
    $date     = sprintf("%04d-%02d-%02d %2d:%02d:%02d  TZ: %s",
                        $y+1900, $m+1, $d, $h, $mi, $sec, $local_tz);

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
        $date_range =~ s/\// to /;
        $hdr .= "#  Statistic:          Instantaneous\n"
              . "#\n"
              . "# Retrieval date range:  $date_range\n";
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


1;
