############################################################################
#
#  W2 Animator
#  Simple HTML Parser for Perl/Tk
#  Copyright (c) 2003-2025, Stewart A. Rounds
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
# Subroutines in this file:
#  create_fonts
#  parse
#  configure_tags
#  get_ops
#  follow_link
#

use strict;
use warnings;
use diagnostics;

#
# List the global variables referenced in this source file.
#
our ($background_color, $cursor_norm, $default_size,
     $have_symbol_font, $main, $pixels_per_pt,
     %link_status,
    );


##########################################################################
#
# Creates a set of font definitions and returns a default font family
# and a list of available fonts, including specific existence information
# for the symbol font.
#
sub create_fonts {
    my ($parent, $default_size) = @_;
    my ($available, $default_family, $font, $have_symbol_font,
        @available_fonts,
       );

#   Get the available font information.  Systems are guaranteed to have
#   Courier, Helvetica, and Times (or surrogate).

    $have_symbol_font = 0;
    @available_fonts = Tkx::SplitList( Tkx::font_families() );
    foreach $available (@available_fonts) {
        if (lc($available) eq "symbol") {
            $have_symbol_font = 1;
            last;
        }
    }
    $default_family = "Helvetica";
    foreach $font ("Helvetica", "Arial", "Times") {
        if ( &list_match($font, @available_fonts) > -1 ) {
            $default_family = $font;
            last;
        }
    }

#   Create some font definitions.

    Tkx::font_create('default', -family     => $default_family,
                                -size       => $default_size,
                                -weight     => 'normal',
                                -slant      => 'roman',
                                -underline  => 0,
                                -overstrike => 0);
    Tkx::font_create('bo',      -family     => $default_family,
                                -size       => $default_size,
                                -weight     => 'bold');
    Tkx::font_create('it',      -family     => $default_family,
                                -size       => $default_size,
                                -slant      => 'italic');
    Tkx::font_create('boit',    -family     => $default_family,
                                -size       => $default_size,
                                -weight     => 'bold',
                                -slant      => 'italic');

    Tkx::font_create('big',     -family     => $default_family,
                                -size       => int(1.5*$default_size));
    Tkx::font_create('bigbo',   -family     => $default_family,
                                -size       => int(1.5*$default_size),
                                -weight     => 'bold');
    Tkx::font_create('bigit',   -family     => $default_family,
                                -size       => int(1.5*$default_size),
                                -slant      => 'italic');
    Tkx::font_create('bigboit', -family     => $default_family,
                                -size       => int(1.5*$default_size),
                                -weight     => 'bold',
                                -slant      => 'italic');

    Tkx::font_create('med',     -family     => $default_family,
                                -size       => int(1.25*$default_size));
    Tkx::font_create('medbo',   -family     => $default_family,
                                -size       => int(1.25*$default_size),
                                -weight     => 'bold');
    Tkx::font_create('medit',   -family     => $default_family,
                                -size       => int(1.25*$default_size),
                                -slant      => 'italic');
    Tkx::font_create('medboit', -family     => $default_family,
                                -size       => int(1.25*$default_size),
                                -weight     => 'bold',
                                -slant      => 'italic');

    Tkx::font_create('sm',      -family     => $default_family,
                                -size       => int(0.65*$default_size));
    Tkx::font_create('smbo',    -family     => $default_family,
                                -size       => int(0.65*$default_size),
                                -weight     => 'bold');
    Tkx::font_create('smit',    -family     => $default_family,
                                -size       => int(0.65*$default_size),
                                -slant      => 'italic');
    Tkx::font_create('smboit',  -family     => $default_family,
                                -size       => int(0.65*$default_size),
                                -weight     => 'bold',
                                -slant      => 'italic');

    Tkx::font_create('cour',     -family     => 'Courier',
                                 -size       => $default_size);
    Tkx::font_create('courbo',   -family     => 'Courier',
                                 -size       => $default_size,
                                 -weight     => 'bold');
    Tkx::font_create('courit',   -family     => 'Courier',
                                 -size       => $default_size,
                                 -slant      => 'italic');
    Tkx::font_create('courboit', -family     => 'Courier',
                                 -size       => $default_size,
                                 -weight     => 'bold',
                                 -slant      => 'italic');

    if ($have_symbol_font) {
        Tkx::font_create('sym',     -family     => 'Symbol',
                                    -size       => $default_size,
                                    -weight     => 'normal',
                                    -slant      => 'roman',
                                    -underline  => 0,
                                    -overstrike => 0);
        Tkx::font_create('symbo',   -family     => 'Symbol',
                                    -size       => $default_size,
                                    -weight     => 'bold');
        Tkx::font_create('symit',   -family     => 'Symbol',
                                    -size       => $default_size,
                                    -slant      => 'italic');
        Tkx::font_create('symboit', -family     => 'Symbol',
                                    -size       => $default_size,
                                    -weight     => 'bold',
                                    -slant      => 'italic');
    }

    return ($default_family, $have_symbol_font, @available_fonts);
}


##########################################################################
#
# The parse subroutine is a simple HTML parser.  It is not fully
# functional, but it handles most of the basic HTML tags.
#
# This subroutine assumes that certain font definitions have been made
# with the "create_fonts" subroutine.  It also assumes that certain global
# variables exist:
#  $have_symbol_font -- need to know for symbols
#  $default_size     -- font size, for sizing things
#  $cursor_norm      -- for setting the mouse shape
#  $background_color -- for setting colors
#  $pixels_per_pt    -- for sizing things
#  %link_status      -- for footer messages
#
sub parse {
    my ($t, $content, $wrapwidth) = @_;
    my (
        $bgcolor, $bold, $borderwidth, $bullet, $cell_char, $center,
        $colspan, $comment, $cs, $file, $font_tag, $hcenter, $i, $image,
        $in_table_cell, $indent, $indent2, $intable, $ipadx, $ipady,
        $italic, $j, $justify, $k, $link, $link_color, $link_ref, $link_tag,
        $listlevel, $lm1, $lm2, $longline, $mark, $match, $max_height,
        $max_width, $n, $nchar, $nf, $nl, $nlines, $ntf, $padx, $pady,
        $pcenter, $pindent, $pos, $pref, $preformat, $relief, $row_bgcolor,
        $rowspan, $safe_to_split, $single_cell, $size, $spanred, $sub,
        $sum, $sup, $symbol, $tbl_bgcolor, $tbold, $tcell, $tcol, $trow,
        $tw, $width,

        @cspan, @current_tags, @frag, @frag2, @line_breaks, @rspan,
        @sizecode, @startrow, @tags, @tframe, @widest_cell,

        %gridinfo, %link_refs, %ops,
       );

    $wrapwidth = 65 if ( ! defined ($wrapwidth) );

    @sizecode = qw/sm reg med big/;
    $size     = $nlines    = $borderwidth   = 1;
    $intable  = $nl        = $in_table_cell = 0;
    $bold     = $italic    = $sub      = $sup       = 0;
    $symbol   = $preformat = $comment  = $link      = 0;
    $center   = $hcenter   = $pcenter  = $spanred   = 0;
    $pindent  = $pref      = $indent   = $indent2   = 0;
    $trow     = $tcol      = $ntf      = $tbold     = 0;
    $padx     = $pady      = $ipadx    = $ipady     = 0;
    $nchar    = $cell_char = $longline = $listlevel = 0;
    $justify  = 'left';
    $bullet   = "\N{U+2022}";
    $link_color = &get_rgb_code("blue");

    &configure_tags($t);

    $content =~ s/^\s+//;
    $content =~ s/\s+$//;

#   Split the content at each tag.
    @frag = split (/</, $content);
    for ($i=1; $i<=$#frag; $i++) {
        $frag[$i] = "<" . $frag[$i];
    }

#   Loop through the tags.
    for ($i=0; $i<=$#frag; $i++) {
        if ( $preformat && $frag[$i] =~ /^<\/pre>/ ) {
            $preformat = 0;
        } elsif ( ! $preformat && $frag[$i] =~ /^<pre>/ ) {
            $preformat = 1;
            substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n";
        }

        if ( ! $preformat ) {
            if ( $comment ) {
                next if ( $frag[$i] !~ /-->/ );
                substr($frag[$i], 0, index($frag[$i], "-->") + 3) = "";
                $comment = 0;
            }

            $frag[$i] =~ s/\s+/ /g;
            $frag[$i] =~ s/<hr>//g;
            $frag[$i] =~ s/<\/?dl>//g;
            $frag[$i] =~ s/<p class=top>//g;

            if ( $frag[$i] =~ /\&micro\;/ ) {
                if ( $have_symbol_font ) {
                    $frag[$i] =~ s/\&micro\;/<font face=symbol>m<\/font>/g;
                    @frag2 = split (/</, $frag[$i]);
                    for ($j=1; $j<=$#frag2; $j++) {
                        $frag2[$j] = "<" . $frag2[$j];
                    }
                    splice(@frag, $i, 1, @frag2);
                } else {
                    $frag[$i] =~ s/\&micro\;/u/g;
                }
            }

            $frag[$i] =~ s/\&uuml\;/u/g;
            $frag[$i] =~ s/\&quot\;/\"/g;
            $frag[$i] =~ s/\&amp\;/\&/g;
            $frag[$i] =~ s/\&gt\;/\>/g;
            $frag[$i] =~ s/\&lt\;/\</g;
            $frag[$i] =~ s/<br>/\n/g;
            $frag[$i] =~ s/<p>/\n\n/g;
            $frag[$i] =~ s/\&nbsp\;/ /g;

            if ( $frag[$i] =~ /^<b>/ ) {
                $bold = 1;

            } elsif ( $frag[$i] =~ /^<\/b>/ ) {
                $bold = 0;

            } elsif ( $frag[$i] =~ /^<strong>/ ) {
                $bold = 1;

            } elsif ( $frag[$i] =~ /^<\/strong>/ ) {
                $bold = 0;

            } elsif ( $frag[$i] =~ /^<i>/ ) {
                $italic = 1;

            } elsif ( $frag[$i] =~ /^<\/i>/ ) {
                $italic = 0;

            } elsif ( $frag[$i] =~ /^<em>/ ) {
                $italic = 1;

            } elsif ( $frag[$i] =~ /^<\/em>/ ) {
                $italic = 0;

            } elsif ( $frag[$i] =~ /^<var>/ ) {
                $italic = 1;

            } elsif ( $frag[$i] =~ /^<\/var>/ ) {
                $italic = 0;

            } elsif ( $frag[$i] =~ /^<sub>/ ) {
                $sub = 1;
                $sup = 0;
                $size--;

            } elsif ( $frag[$i] =~ /^<\/sub>/ ) {
                $sub = 0;
                $size++;

            } elsif ( $frag[$i] =~ /^<sup>/ ) {
                $sup = 1;
                $sub = 0;
                $size--;

            } elsif ( $frag[$i] =~ /^<\/sup>/ ) {
                $sup = 0;
                $size++;

            } elsif ( $frag[$i] =~ /^<font face=symbol>/ ) {
                $symbol = 1;

            } elsif ( $frag[$i] =~ /^<\/font>/ ) {
                $symbol = 0;

            } elsif ( $frag[$i] =~ /^<a href="/ ) {
                $frag[$i] = substr($frag[$i], 9);
                $pos = index($frag[$i], "\"");
                if ( $pos > -1 ) {
                    $link_ref = substr($frag[$i], 0, $pos);
                    if ( $link_ref =~ /^\// ) {
                        if ( $link_ref eq "/w2anim" ||
                             $link_ref eq "/w2anim/w2anim.html" ) {
                            $link_ref = "W2 Animator";
                        } else {
                            substr($link_ref, 0, 0) = "file:";
                        }
                    }
                    if ( $link_ref !~ /^xxmailto/ ) {
                        $link = 1;
                        $link_tag = "link$nl";
                        $nl++;
                        if (! $intable) {
                            $tw = $t;
                        } elsif ( $in_table_cell ) {
                            $tw = $tcell;
                        }
                        $link_refs{$tw}{$link_tag} = $link_ref;
                        $tw->tag_configure($link_tag, -underline => 1,
                                            -foreground => $link_color,
                                            );
                        $tw->tag_bind($link_tag, "<Any-Enter>", [
                            sub { $tw = shift;
                                  $tw->configure(-cursor => 'hand2');
                                  @current_tags = Tkx::SplitList($tw->tag_names('current'));
                                  $match = &list_search('link*', @current_tags);
                                  return if ($match < 0);
                                  $link_status{Tkx::winfo_toplevel($tw)}
                                      = $link_refs{$tw}{$current_tags[$match]};
                                }, $tw ]);
                        $tw->tag_bind($link_tag, "<Any-Leave>", [
                            sub { $tw = shift;
                                  $tw->configure(-cursor => $cursor_norm);
                                  $link_status{Tkx::winfo_toplevel($tw)} = "";
                                }, $tw ]);
                        $tw->tag_bind($link_tag, "<Button-1>", [
                            sub { $tw = shift;
                                  @current_tags = Tkx::SplitList($tw->tag_names('current'));
                                  $match = &list_search('link*', @current_tags);
                                  return if ($match < 0);
                                  &follow_link($link_refs{$tw}{$current_tags[$match]}, $tw);
                                }, $tw ]);
                    }
                }

            } elsif ( $frag[$i] =~ /^<a name="/ ) {
                $frag[$i] = substr($frag[$i], 9);
                $pos = index($frag[$i], "\"");
                if ( $pos > -1 ) {
                    $mark = substr($frag[$i], 0, $pos);
                    if (! $intable) {
                        $t->mark_set($mark, 'current');
                        $t->mark_gravity($mark, 'left');
                    } elsif ( $in_table_cell ) {
                        $tcell->mark_set($mark, 'current');
                        $tcell->mark_gravity($mark, 'left');
                    }
                }

            } elsif ( $frag[$i] =~ /^<\/a>/ ) {
                $link = 0;

            } elsif ( $frag[$i] =~ /^<img / ) {
                $frag[$i] = substr($frag[$i], 5);
                $pos = index($frag[$i], "src=\"");
                if ( $pos > -1 ) {
                    $frag[$i] = substr($frag[$i], $pos + 5);
                    $pos = index($frag[$i], "\"");
                    if ( $pos > -1 ) {
                        $file  = substr($frag[$i], 0, $pos);
                        $image = $t->new_label(-image => Tkx::image_create_photo(-file => $file));
                        if (! $intable) {
                            $t->window_create('end', -window => $image);
                        } elsif ( $in_table_cell ) {
                            $tcell->window_create('end', -window => $image);
                        }
                        # add to nlines if image is taller than text
                        %ops = &get_ops($frag[$i]);
                        $j = int( $ops{'height'} / $pixels_per_pt
                                        / $default_size -0.6);
                        $nlines += $j if ( $j > 0 );
                    }
                }

            } elsif ( $frag[$i] =~ /^<center>/ ) {
                $center = 1;

            } elsif ( $frag[$i] =~ /^<\/center>/ ) {
                $center = 0;

            } elsif ( $frag[$i] =~ /^<h[1-9]>/ ) {
                $size   += 2 if ( $frag[$i] =~ /^<h[12]>/ );
                $size   += 1 if ( $frag[$i] =~ /^<h[34]>/ );
                $bold    = 1 if ( $frag[$i] =~ /^<h[1235]>/ );
                $italic  = 1 if ( $frag[$i] =~ /^<h6>/ );
                $hcenter = 1 if ( $frag[$i] =~ /^<h[12]>/ );
                substr($frag[$i], index($frag[$i], ">") +1, 0) = "\n";
                substr($frag[$i], index($frag[$i], ">") +1, 0) = "\n" if ($i>2);

            } elsif ( $frag[$i] =~ /^<\/h[1-9]>/ ) {
                $size   -= 2 if ( $frag[$i] =~ /^<\/h[12]>/ );
                $size   -= 1 if ( $frag[$i] =~ /^<\/h[34]>/ );
                $bold    = 0 if ( $frag[$i] =~ /^<\/h[1235]>/ );
                $italic  = 0 if ( $frag[$i] =~ /^<\/h6>/ );
                $hcenter = 0 if ( $frag[$i] =~ /^<\/h[12]>/ );

            } elsif ( $frag[$i] =~ /^<p class=indent>/ ) {
                $pindent = 1;
                $indent++;
                substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n\n";

            } elsif ( $frag[$i] =~ /^<p class=center>/ ) {
                $pcenter = 1;
                substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n\n";

            } elsif ( $frag[$i] =~ /^<p class=reference>/ ) {
                $pref = 1;
                $indent++;
                $indent2++;
                substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n\n";

            } elsif ( $frag[$i] =~ /^<\/p>/ ) {
                $indent--  if ($pindent || $pref);
                $indent2-- if ($pref);
                $pindent = $pcenter = $pref = 0;

            } elsif ( $frag[$i] =~ /^<span class=red>/ ) {
                $spanred = 1;

            } elsif ( $frag[$i] =~ /^<\/span>/ ) {
                $spanred = 0;

            } elsif ( $frag[$i] =~ /^<dt>/ ) {
                substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n\n";

            } elsif ( $frag[$i] =~ /^<\/dt>/ ) {

            } elsif ( $frag[$i] =~ /^<dd>/ ) {
                $indent++;
                substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n";

            } elsif ( $frag[$i] =~ /^<\/dd>/ ) {
                $indent--;

            } elsif ( $frag[$i] =~ /^<ul>/ ) {
                $indent++;
                $listlevel++;
                $bullet = ($listlevel % 2 == 0) ? "\N{U+25E6}" : "\N{U+2022}";

            } elsif ( $frag[$i] =~ /^<li>/ ) {
                $indent2++;
                substr($frag[$i], index($frag[$i], ">") + 1, 0) = "\n$bullet ";

            } elsif ( $frag[$i] =~ /^<\/li>/ ) {
                $indent2--;

            } elsif ( $frag[$i] =~ /^<\/ul>/ ) {
                $indent--;
                $listlevel--;
                $bullet = ($listlevel % 2 == 0) ? "\N{U+25E6}" : "\N{U+2022}";

            } elsif ( $frag[$i] =~ /^<!--/ ) {
                $comment = 1;
                next if ( $frag[$i] !~ /-->/ );
                substr($frag[$i], 0, index($frag[$i], "-->") + 3) = "";
                $comment = 0;

            } elsif ( $frag[$i] =~ /^<table/ ) {
                $intable = 1;
                $trow = $tcol = $ntf = -1;
                @rspan = @cspan = ();
                @startrow = ();
                @widest_cell = ();

                %ops = &get_ops($frag[$i]);
                $padx = $pady = 0;
                $padx = $pady = $ops{'cellspacing'} if ( $ops{'cellspacing'} );
                $ipadx = $ipady = 0;
                $ipadx = $ipady = $ops{'cellpadding'} if ( $ops{'cellpadding'});
                $borderwidth = 1;
                $borderwidth = $ops{'border'} if ( defined($ops{'border'}) );
                if ( $borderwidth == 0 ) {
                    $relief = 'flat';
                } else {
                    $borderwidth++;
                    $relief = 'raised';
                }
                $tbl_bgcolor = $background_color;
                $tbl_bgcolor = $ops{'bgcolor'} if ( $ops{'bgcolor'} );
                $tbl_bgcolor = &get_rgb_code($tbl_bgcolor);
                $t->insert('end', "\n");

                $longline = $nchar if ( $nchar > $longline );
                $nlines += 1 + int($nchar/$wrapwidth);
                $nchar = 0;

            } elsif ( $frag[$i] =~ /^<tr/ ) {
                $trow++;
                $tcol = -1;
                %ops = &get_ops($frag[$i]);
                $row_bgcolor = $tbl_bgcolor;
                $row_bgcolor = $ops{'bgcolor'} if ( $ops{'bgcolor'} );
                $row_bgcolor = &get_rgb_code($row_bgcolor);

#               Scrolled text widgets don't scroll well over large embedded
#               widgets.  Therefore, split each row of the table into a
#               separate frame, as long as not prohibited by a rowspan.
#               Don't split if each column can't be separately configured.

                if ( $trow > 0 ) {
                    $safe_to_split = 1;
                    $safe_to_split = 0 if ( $#{$rspan[$trow]} >= 0 );
                    for ($j=0; $j<=$#{$cspan[$startrow[$ntf]]}; $j++) {
                        $single_cell = 0;
                        for ($k=$startrow[$ntf]; $k<$trow; $k++) {
                            $single_cell = 1 if ( $cspan[$k][$j] == 0 );
                        }
                        $safe_to_split = 0 if ( ! $single_cell );
                    }
                }
                if ( $trow == 0 || $safe_to_split ) {
                    $ntf++;
                    $startrow[$ntf] = $trow;
                    if ( $indent || $center || $pcenter || $hcenter ) {
                        @tags = ();
                        push (@tags, 'center') if ($center||$pcenter||$hcenter);
                        $indent  = 0 if ($indent  < 0);
                        $indent  = 3 if ($indent  > 3);
                        $indent2 = 0 if ($indent2 < 0);
                        $indent2 = 1 if ($indent2 > 1);
                        $lm1 = sprintf("%.1fc", 0.4 * $indent);
                        $lm2 = sprintf("%.1fc", 0.4 * $indent + 0.4 * $indent2);
                        $t->tag_configure("indent$indent$indent2",
                                          -lmargin1 => $lm1,
                                          -lmargin2 => $lm2);
                        push (@tags, "indent$indent$indent2");
                        $t->tag_configure('nowrap', -wrap => 'none',
                                          -foreground => &get_rgb_code($background_color));
                        push (@tags, 'nowrap');
                        $t->insert('end', "\n.", \@tags);
                    } else {
                        $t->insert('end', "\n");
                    }
                    $tframe[$ntf] = $t->new_frame();
                    $t->window_create('end', -window => $tframe[$ntf]);
                }

            } elsif ( $frag[$i] =~ /^<t[hd]/ ) {
                if ( $frag[$i] =~ /^<th/ ) {
                    $tbold = 1;
                    $justify = 'center';
                } else {
                    $tbold = 0;
                    $justify = 'left';
                }

                $trow++ if ( $trow < 0 );
                $tcol++;
                $widest_cell[$tcol] = 0 if ($trow == 0);
                $tcol++ until ( ! $rspan[$trow][$tcol]
                             && ! $cspan[$trow][$tcol] );
                %ops = &get_ops($frag[$i]);

                $justify = $ops{'align'} if ( $ops{'align'} );
                $bgcolor = $row_bgcolor;
                $bgcolor = $ops{'bgcolor'} if ( $ops{'bgcolor'} );
                $bgcolor = &get_rgb_code($bgcolor);

#               rspan is undef if not spanned from another row
#               cspan is either 0 or 1 to indicate membership in a colspan

                $rowspan = $colspan = 1;
                $colspan = $ops{'colspan'} if ( $ops{'colspan'} );
                $rowspan = $ops{'rowspan'} if ( $ops{'rowspan'} );
                $cspan[$trow][$tcol] = 0;
                for ($k=$tcol; $k<$tcol+$colspan; $k++) {
                    $cspan[$trow][$k] = 1 if ( $colspan > 1 );
                    for ($j=$trow+1; $j<$trow+$rowspan; $j++) {
                        $rspan[$j][$k] = 1;
                        $cspan[$j][$k] = 0;
                        $cspan[$j][$k] = 1 if ( $colspan > 1 );
                    }
                }
                $tcell = $tframe[$ntf]->new_tkx_ROText(
                        -width       => 20,
                        -height      => $rowspan,
                        -font        => 'default',
                        -cursor      => $cursor_norm,
                        -wrap        => 'word',
                        -relief      => $relief,
                        -background  => $bgcolor,
                        -borderwidth => $borderwidth,
                        -insertwidth => 0,
                        );
                $tcell->g_grid(-row        => $trow - $startrow[$ntf],
                               -rowspan    => $rowspan,
                               -column     => $tcol,
                               -columnspan => $colspan,
                               -sticky     => 'nsew',
                               -padx       => $padx,
                               -pady       => $pady,
                               -ipadx      => $ipadx,
                               -ipady      => $ipady,
                               );
                &configure_tags($tcell);
                $in_table_cell = 1;
                $cell_char = 0;
                @line_breaks = ();

            } elsif ( $frag[$i] =~ /^<\/t[hd]>/ ) {
                $tbold = 0;
                $in_table_cell = 0;
                if ( $#line_breaks < 0 ) {
                    $max_width  = $cell_char;
                    $max_height = $rowspan;
                } else {
                    $max_width = $line_breaks[0];
                    for ($j=1; $j<=$#line_breaks; $j++) {
                        $width = $line_breaks[$j] - $line_breaks[$j-1];
                        $max_width = $width if ( $width > $max_width );
                    }
                    $max_height = $#line_breaks + 2;
                }
                $tcell->configure(-width  => $max_width,
                                  -height => $max_height,
                                  -state  => 'readonly');
                if ( $max_width > $widest_cell[$tcol]
                     && ! $cspan[$trow][$tcol]) {
                    $widest_cell[$tcol] = $max_width;
                }

            } elsif ( $frag[$i] =~ /^<\/tr>/ ) {

            } elsif ( $frag[$i] =~ /^<\/table>/ ) {
                $intable = 0;

#               If tables have been split into different frames,
#               figure out if any cell that spans columns is wider than
#               the sum of the widest columns they span.  If so, adjust
#               the individual column widths so that they are wider than
#               the spanning column.

                $startrow[$ntf+1] = -1;
                if ( $ntf > 0 ) {
                    $nf = -1;
                    for ($j=0; $j<=$trow; $j++) {
                        $nf++ if ( $j == $startrow[$nf+1] );
                        for ($k=0; $k<=$#{$cspan[0]}; $k++) {
                            if ( $cspan[$j][$k] == 1
                                 && ( $k == 0 ||
                                    ( $k > 0 && $cspan[$j][$k-1] == 0 ) )) {
                                $tcell = $tframe[$nf]->grid_slaves(
                                           -row => $j - $startrow[$nf],
                                           -column => $k);
                                $width    = $tcell->cget(-width);
                                %gridinfo = $tcell->grid_info();
                                $cs = $gridinfo{'-columnspan'};
                                for ($n=0; $n<$cs; $n++) {
                                    $sum += $widest_cell[$k + $n];
                                }
                                if ( $sum < $width ) {
                                    for ($n=0; $n<$cs; $n++) {
                                        $widest_cell[$k + $n]
                                          += int(($width - $sum) / $cs) + 1;
                                    }
                                }
                            }
                        }
                    }

#                   Force columns in different frames to have same widths.

                    $nf = -1;
                    for ($j=0; $j<=$trow; $j++) {
                        $nf++ if ( $j == $startrow[$nf+1] );
                        for ($k=0; $k<=$#{$cspan[0]}; $k++) {
                            if ( $cspan[$j][$k] == 0 ) {
                                $tcell = $tframe[$nf]->grid_slaves(
                                           -row => $j - $startrow[$nf],
                                           -column => $k);
                                $tcell->configure(
                                           -width => $widest_cell[$k]);
                            }
                        }
                    }
                }
                $nlines += int($trow * (2.0 + ($pady + $ipady)
                                     /$pixels_per_pt/$default_size));
                $j = 0;
                for ($k=0; $k<=$#{$cspan[0]}; $k++) {
                    $j += $widest_cell[$k];
                }
                $longline = $j if ( $j > $longline );
            }

        }
        substr($frag[$i], 0, index($frag[$i], ">") + 1) = "";
        if ( $i == 0 || ( $i == 1 && $frag[0] eq "" ) ) {
            $frag[$i] =~ s/^\n+//;
        }

        if ( $frag[$i] ) {
            if ( $symbol ) {
                $font_tag = 'sym';
            } elsif ( $preformat ) {
                $font_tag = 'cour';
            } else {
                $size = 0 if ($size < 0);
                $size = 3 if ($size > 3);
                $font_tag = $sizecode[$size];
            }
            $font_tag .= "bo" if ( $bold || $tbold );
            $font_tag .= "it" if ( $italic );
            @tags = ( $font_tag );
            if ( ! $preformat ) {
                push (@tags, 'sup')     if ($sup);
                push (@tags, 'sub')     if ($sub);
                push (@tags, 'red')     if ($spanred);
                push (@tags, $link_tag) if ($link);
                if ( ! $intable ) {
                    $indent  = 0 if ($indent  < 0);
                    $indent  = 3 if ($indent  > 3);
                    $indent2 = 0 if ($indent2 < 0);
                    $indent2 = 1 if ($indent2 > 1);
                    if ( $indent ) {
                        $lm1 = sprintf("%.1fc", 0.4 * $indent);
                        $lm2 = sprintf("%.1fc", 0.4 * $indent + 0.4 * $indent2);
                        $t->tag_configure("indent$indent$indent2",
                                          -lmargin1 => $lm1,
                                          -lmargin2 => $lm2);
                        push (@tags, "indent$indent$indent2");
                    }
                    push (@tags, 'center') if ($center || $pcenter || $hcenter);
                }
            }
            if (! $intable) {
                $t->insert('end', $frag[$i], \@tags);
            } elsif ( $in_table_cell ) {
                push (@tags, $justify);
                $tcell->insert('end', $frag[$i], \@tags);
            }
        }
        if (! $intable) {
            $j = -1;
            until ( index($frag[$i], "\n", $j+1) == -1 ) {
                $nchar += index($frag[$i], "\n", $j+1) - ($j+1);
                $longline = $nchar if ( $nchar > $longline );
                $nlines += 1 + int($nchar/$wrapwidth);
                $nchar = 0;
                $j = index($frag[$i], "\n", $j+1);
            }
            $nchar += length($frag[$i]) - ($j + 1);
            $longline = $nchar if ( $nchar > $longline );
        } elsif ( $in_table_cell ) {
            $j = -1;
            until ( index($frag[$i], "\n", $j+1) == -1 ) {
                $j = index($frag[$i], "\n", $j+1);
                push (@line_breaks, $cell_char + $j);
            }
            $cell_char += length($frag[$i]);
        }
    }
    $t->configure(-state => 'readonly');
    $nlines += int($nchar/$wrapwidth);
    $longline = $wrapwidth if ( $longline > $wrapwidth );
    return $longline, $nlines;
}


##########################################################################
#
# Configures tags used in text windows.
#
# Assumes $default_size is a global variable.
#
sub configure_tags {
    my ($t) = @_;

    $t->tag_configure('reg',      -font => 'default');
    $t->tag_configure('regbo',    -font => 'bo');
    $t->tag_configure('regit',    -font => 'it');
    $t->tag_configure('regboit',  -font => 'boit');
    $t->tag_configure('big',      -font => 'big');
    $t->tag_configure('bigbo',    -font => 'bigbo');
    $t->tag_configure('bigit',    -font => 'bigit');
    $t->tag_configure('bigboit',  -font => 'bigboit');
    $t->tag_configure('med',      -font => 'med');
    $t->tag_configure('medbo',    -font => 'medbo');
    $t->tag_configure('medit',    -font => 'medit');
    $t->tag_configure('medboit',  -font => 'medboit');
    $t->tag_configure('sm',       -font => 'sm');
    $t->tag_configure('smbo',     -font => 'smbo');
    $t->tag_configure('smit',     -font => 'smit');
    $t->tag_configure('smboit',   -font => 'smboit');
    $t->tag_configure('sym',      -font => 'sym');
    $t->tag_configure('symbo',    -font => 'symbo');
    $t->tag_configure('symit',    -font => 'symit');
    $t->tag_configure('symboit',  -font => 'symboit');
    $t->tag_configure('cour',     -font => 'cour');
    $t->tag_configure('courbo',   -font => 'courbo');
    $t->tag_configure('courit',   -font => 'courit');
    $t->tag_configure('courboit', -font => 'courboit');

    $t->tag_configure('sup',      -offset   => int(0.75*$default_size));
    $t->tag_configure('sub',      -offset   => -int(0.25*$default_size));
    $t->tag_configure('center',   -justify  => 'center');
    $t->tag_configure('left',     -justify  => 'left');
    $t->tag_configure('right',    -justify  => 'right');
    $t->tag_configure('red',      -foreground => &get_rgb_code('red'));
}


##########################################################################
#
# Gets options from HTML tags.
#
sub get_ops {
    my ($s) = @_;
    my %ops = ();
    my ($i, $key, $value);

    $s =~ s/^<\w+\s*//;                  # clip off the tag
    $s = substr($s, 0, index($s, ">"));  # clip off the end
    $s =~ s/\s+$//;                      # clip off dangling whitespace
    until ( $s eq "" ) {
        $i = index($s, "=");
        last if ( $i == -1 );
        $key = substr($s, 0, $i);
        substr($s, 0, $i+1) = "";
        if ( $s =~ /^\"/ ) {
            $i = index($s, "\"", 1);
            last if ( $i == -1 );
            $value = substr($s, 1, $i-1);
            substr($s, 0, $i+1) = "";
            $s =~ s/^\s+//;
        } else {
            $i = index($s, " ");
            if ( $i > -1 ) {
                $value = substr($s, 0, $i);
                substr($s, 0, $i+1) = "";
            } else {
                $value = $s;
                $s = "";
            }
        }
        $ops{$key} = $value;
    }

#   Input constraints:
    if ( $ops{'align'} ) {
        delete $ops{'align'}
          if ( &list_match(lc($ops{'align'}), qw/left right center/) == -1 );
    }
    if ( $ops{'rowspan'} ) {
        $ops{'rowspan'} = int($ops{'rowspan'});
        delete $ops{'rowspan'} if ( $ops{'rowspan'} <= 1 );
    }
    if ( $ops{'colspan'} ) {
        $ops{'colspan'} = int($ops{'colspan'});
        delete $ops{'colspan'} if ( $ops{'colspan'} <= 1 );
    }
    if ( $ops{'border'} ) {
        $ops{'border'} = int($ops{'border'});
        delete $ops{'border'} if ( $ops{'border'} < 0 );
    }
    if ( $ops{'cellpadding'} ) {
        $ops{'cellpadding'} = int($ops{'cellpadding'});
        delete $ops{'cellpadding'} if ( $ops{'cellpadding'} <= 0 );
    }
    if ( $ops{'cellspacing'} ) {
        $ops{'cellspacing'} = int($ops{'cellspacing'});
        delete $ops{'cellspacing'} if ( $ops{'cellspacing'} <= 0 );
    }
    if ( $ops{'width'} ) {
        $ops{'width'} = int($ops{'width'});
        delete $ops{'width'} if ( $ops{'width'} <= 0 );
    }
    if ( $ops{'height'} ) {
        $ops{'height'} = int($ops{'height'});
        delete $ops{'height'} if ( $ops{'height'} <= 0 );
    }
    return %ops;
}


##########################################################################
#
# The follow_link subroutine works with the parse subroutine to activate
# hyperlinks in a text window.
#
# This routine assumes that certain global variables exist:
#  $main             -- the main window
#  $background_color -- the window background color
#  $cursor_norm      -- the normal mouse cursor shape
#
# It also sets the following variables so that they'll be remembered.
#  @window           -- addresses of open windows
#  @windowlist       -- list of open windows
#
{
  my (@windowlist, @window);

  sub follow_link {
    my ($link, $tw) = @_;
    my ($content, $fh, $gk, $i, $kid, $linein, $spot,
        @grandkids, @kids,
       );

    # Check for an internal hyperlink.
    if ( $link =~ /^#/ ) {
        if ( Tkx::winfo_exists($tw) ) {
            $link =~ s/^#//;
            $tw->see($link);
        }

    # Check for a link to the main page.
    } elsif ( $link eq "W2 Animator" ) {
        $main->g_wm_deiconify();
        $main->g_raise();
        $main->g_focus;

    # Open a hyperlink to an external site by starting up a browser.
    } elsif ( $link =~ /^http:\/\// || $link =~ /^https:\/\// ) {
        &open_url($link, $tw);

    # Open up a mailto link.
    } elsif ( $link =~ /^mailto:/ ) {
        &open_url($link, $tw);

    # Otherwise, follow a hyperlink to a local document.
    } else {

        # Split up the link, if necessary.

        if ( index($link, "#") > 0 ) {
            $i    = index($link, "#");
            $spot = substr($link, $i+1);
            substr($link, $i) = "";
        }

        # Keep track of open windows in a global array.
        # Determine when one is already open.

        $i = &list_match($link, @windowlist);
        if ( $i > -1 ) {
            if ( Tkx::winfo_exists($window[$i]) ) {
                $window[$i]->g_wm_deiconify();
                $window[$i]->g_raise();
                $window[$i]->g_focus;
                if ( $spot ) {
                    @kids = Tkx::winfo_children($window[$i]);
                    foreach $kid (@kids) {
                        @grandkids = Tkx::winfo_children($kid);
                        $gk = &list_search("ROText", @grandkids);
                        last if ( $gk > -1 );
                    }
                    $grandkids[$gk]->see($spot) if ( $gk > -1 );
                }
            } else {
                undef $windowlist[$i];
                $i = -1;
            }
        }
        if ( $i == -1 ) {
            open ($fh, $link)
                or return &pop_up_error($tw, "Unable to open\n$link");
            push (@windowlist, $link);
            $i = $#windowlist;
            $link =~ s/\.html$//;
            $link =~ s/_/ /g;
            $link = ucfirst($link);
            $main->g_tk_busy();
            Tkx::update();
            $window[$i] = $main->new_toplevel();
            $window[$i]->g_wm_title($link);
            $window[$i]->g_wm_minsize(350,250);
            $window[$i]->configure(-cursor => $cursor_norm);
            &footer($window[$i]);
            $tw = $window[$i]->new_tkx_Scrolled('tkx_ROText',
                -relief      => 'flat',
                -font        => 'default',
                -background  => &get_rgb_code($background_color),
                -cursor      => $cursor_norm,
                -wrap        => 'word',
                -scrollbars  => 'oe',
                -height      => 30,
                -insertwidth => 0,
                );
            $tw->g_pack(-fill => 'both', -expand => 1);

            if ( $link eq "Gpl" ) {
                $content = "";
                until (<$fh> =~ /<\/head>/) {}
                while ( defined ($linein = <$fh>) ) {
                    $content .= $linein;
                }
            } else {
                $content = "<img src=\"images/usgs.gif\" width=72 height=20>";
                until (<$fh> =~ /includes\/owsc_header/) {}
                while ( defined ($linein = <$fh>) ) {
                    last if ( $linein =~ /includes\/owsc_footer/ );
                    $content .= $linein;
                }
            }
            close ($fh);
            &parse($tw, $content);
            $window[$i]->g_focus;
            $tw->see($spot) if ( $spot );
            $main->g_tk_busy_forget();
        }
    }
  }
}

1;
