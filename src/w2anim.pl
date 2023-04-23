#!/usr/bin/perl
############################################################################
#
#  W2 Animator
#  Perl Tcl/Tk Version
#  Copyright (c) 2022-2023, Stewart A. Rounds
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

# Set aside variable for program use.
our ($prog_path, $version);

# Determine invocation path to program, to ensure loading of other files.
($prog_path = $0) =~ s/(.*)[\/\\]w2anim.pl/$1/;

# Set the version.
$version = "v0.9.0 // [23-Apr-2023]";

# Print message to screen.
print << "end_of_input";
W2 Animator
Version $version
Copyright (c) 2022-2023, Stewart A. Rounds

This is free software and may be redistributed and/or modified
under the terms of the GNU General Public License as published
by the Free Software Foundation.
end_of_input

# Load the RGB color code info.
require "${prog_path}/w2anim_rgb.pl" or die "unable to load RGB color code info\n";

# Load some utilities.
require "${prog_path}/w2anim_utils.pl" or die "unable to load utilities\n";

# Load the HTML parser.
require "${prog_path}/w2anim_parser.pl" or die "unable to load fonts and parser\n";

# Load the subroutines that read and manipuldate data.
require "${prog_path}/w2anim_datasubs.pl" or die "unable to load data subroutines\n";

# Load the W2 input subroutines.
require "${prog_path}/w2anim_w2subs.pl" or die "unable to load W2 subroutines\n";

# Load the interface.  Do this last.
require "${prog_path}/w2anim_gui.pl" or die "unable to load graphical interface\n";

exit;
