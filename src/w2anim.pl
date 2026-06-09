#!/usr/bin/perl
############################################################################
#
#  W2 Animator
#  Perl Tcl/Tk Version
#  Copyright (c) 2022-2026, Stewart A. Rounds
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

use strict;
use warnings;
use diagnostics;
use File::Spec;

# Set aside variable for program use.
our ($load_w2a, $prog_path, $version);
my  ($filepath);

# Determine absolute invocation path to program, to ensure loading of other files.
($prog_path = File::Spec->rel2abs($0)) =~ s/(.*[\/\\]?)w2anim.pl/$1/;

# Determine whether a project file is to be loaded immediately.
$load_w2a = (defined($ARGV[0]) && $ARGV[0] =~ /.+\.w2a$/) ? $ARGV[0] : "";

# Set the version.
$version = "1.7.2 [8-Jun-2026]";

# Print message to screen.
print << "end_of_input";
W2 Animator
Version $version
Copyright (c) 2022-2026, Stewart A. Rounds

This is free software and may be redistributed and/or modified
under the terms of the GNU General Public License as published
by the Free Software Foundation.
end_of_input

# Load the RGB color code info.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_rgb.pl"));
require $filepath or die "Unable to load RGB color code info from\n  $filepath\n";

# Load some utilities.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_utils.pl"));
require $filepath or die "Unable to load utilities from\n  $filepath\n";

# Load the HTML parser.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_parser.pl"));
require $filepath or die "Unable to load fonts and parser from\n  $filepath\n";

# Load the subroutines that read and manipuldate data.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_datasubs.pl"));
require $filepath or die "Unable to load data subroutines from\n  $filepath\n";

# Load the W2 input subroutines.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_w2subs.pl"));
require $filepath or die "Unable to load W2 subroutines from\n  $filepath\n";

# Load some data-retrieval codes.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_datacodes.pl"));
require $filepath or die "Unable to load data-retrieval codes from\n  $filepath\n";

# Load some data-retrieval subroutines.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_getdata.pl"));
require $filepath or die "Unable to load data-retrieval subroutines from\n  $filepath\n";

# Load the interface.  Do this last.
$filepath = File::Spec->rel2abs(File::Spec->catfile($prog_path, "w2anim_gui.pl"));
require $filepath or die "Unable to load graphical interface from\n  $filepath\n";

exit;
