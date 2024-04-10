# Change Log - The W2 Animator

All notable changes to The W2 Animator (W2Anim) will be logged to this file.


### [v1.1.0](https://github.com/sarounds/w2anim/releases/tag/v1.1.0) \[9-Apr-2024\]

This is a major update, as it includes a new graph type (W2 Time/Distance
Maps), a number of new color schemes, the ability to read two new types of
CE-QUAL-W2 output files (W2 Lake Contour files and W2 River Contour files),
an expanded initialization file, and a number of other additions and fixes.
See the updated
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
for more details.

#### Changed

- A few more pieces of the W2 control file are now read and saved, to support
  certain functions of W2Anim.

- An additional quality assurance check was done on segment lengths when
  reading W2 vector output files.

- Code was modified to distinguish among several USGS custom W2 output files
  (SurfTemp, VolTemp, and FlowTemp files). The use of a profile statistic
  in the new W2 Time/Distance Map plots required W2Anim to be able to scan
  and recognize the differences among those output files.

- A subroutine that forced certain entries to be numeric was modified so that
  it could also allow the word "auto" in certain instances, especially
  for entries that govern a major tick spacing.

- The Viridis color scheme was added as one of the potential initial choices
  when a user first manually creates a new graph.

- Changed the code so that the program-set or user-defined default font
  family is used as the initial font family for text in new graphs. The
  initial font had previously been hard-wired to be Arial Narrow.

#### Fixed

- A fix was made to ensure that W2 contour output files are read properly
  after the CE-QUAL-W2 code was changed and the length of some variables
  holding parameter names was changed.

- A number of miscellaneous small fixes were made, including corrections
  to a couple of misspelled words.

#### Added

- Each of the program defaults was added to an expanded W2Anim initialization
  file (w2anim.ini). See the updated
  [User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
  for more details.

- W2Anim can now read W2 Lake Contour output files (format 1) as input to
  W2 Vertical Profile or W2 Vertical Profile Colormap graphs, or as a
  color-highlighting input to W2 Outflow Profile graphs.

- A new W2 Time/Distance Map plot was added to W2Anim. These plots show
  date/time on one axis and longitudinal distance on the other axis, and
  colors are used to visualize spatial and temporal variations in the value
  of a plotted model-output parameter. W2Anim can read several types of
  W2 output files for this new plot type, including the W2 River Contour
  output file, which was not part of previous versions.  Routines were
  added to read files, create plots, calculate parameter differences, make
  changes to parameter choices, undo and reverse difference calculations,
  and swap axes.

- Both the W2 Time/Distance Map and W2 Longitudinal Slice plots were given
  the ability to set a first labelled distance tick mark that is different
  from the distance axis minimum value, thus allowing for cleaner tick
  marks and more accurate river-mile or river-kilometer axes.

- Seven new color schemes were added to W2Anim. These color schemes are all
  from the [Scientific Color Maps](https://www.fabiocrameri.ch/colourmaps/)
  package produced by Fabio Crameri, and are free for use and redistribution.


### [v1.0.1](https://github.com/sarounds/w2anim/releases/tag/v1.0.1) \[25-Nov-2023\]

This version includes important changes, fixes, and significant new
capabilities. W2 vector output files (DSI linkage files) now can be read
as a source of information for W2 Vertical Profile, W2 Vertical Profile
Colormap, W2 Longitudinal Slice, and W2 Outflow Profile graphs. This
version allows the user to change the segment, parameter, parameter units,
begin year, date-skip setting, and data source files for existing W2
Vertical Profile and W2 Vertical Profile Colormap graphs, as well as the
parameter, parameter units, begin year, and date-skip setting for existing
W2 Longitudinal Slice graphs.  See the updated
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
for more details.

#### Changed

- A few checks on input were streamlined for the subroutine that reads a
  W2 bathymetry file. This change was spurred by a user-reported problem,
  and the input checks that were removed were not strictly necessary.

- Subroutines that scan W2 spreadsheet and contour output files for
  segment and parameter lists were modified so that in some situations they
  do not have to read the entire file or return the number of source lines.
  Code was added to add certain velocity and flow outputs to the parameter
  lists, when such parameters are available.

- A few changes were made to the content of W2Anim project files (*.w2a)
  related to the potential use of W2 vector output files as input. Older
  W2Anim project files should still be compatible.

#### Fixed

- A couple of small errors in the duplicate subroutine were fixed.

- An error in the determine_ts_type subroutine related to the parameter index
  for column-format W2-style input/output files was fixed.

- A problem with the time-series zoom functions that sometimes set a zero
  value for the x-axis major spacing was fixed.

- A small error in the placement of the highest virtual outlets in the
  libby_calcs subroutine was fixed, and a bit more error checking was
  added. Code also was added to trap for and properly handle root-bounding
  conditions in the zbrent_howington subroutine that finds an optimal
  head-drop for the Libby-type dam outlet calculations.

#### Added

- New code was added to allow a user to change certain key characteristics
  of W2Anim's W2 Vertical Profile, W2 Vertical Profile Colormap, and W2
  Longitudinal Slice graph types. For W2 Vertical Profile and Vertical
  Profile Colormap plots, the user can take an existing graph and change
  the segment number, the parameter, the parameter units, the W2 begin
  year, the date-skip setting, and even the input files for the plot. For
  W2 Longitudinal Slice graphs, the user can change the parameter, the
  parameter units, the W2 begin year, and the date-skip setting.

- New code was added to the make_date_axis subroutine so that the days of the
  month are automatically added to a Month axis when the date range is
  relatively short, say only a couple of months. This change is responsive
  to the amount of space available, taking into account the font size.
  A single-letter month abbreviation for Month axes also was added for
  situations when limited space is available.

- Subroutines were added to the w2anim_w2subs.pl source file to allow W2Anim
  to read W2 vector output files. In addition, information about W2 vector
  output is now read and stored when a W2 control file is read.

- The convert_cpl_data subroutine was renamed to convert_slice_data and
  code was added to ensure that it would work for data read from W2 vector
  output files as well as for data read from W2 contour output files.


### [v0.9.7](https://github.com/sarounds/w2anim/releases/tag/v0.9.7) \[02-Oct-2023\]

Changes to this version are minor but important, including an addition to
the initialization file, an update to reflect changes to W2 version 4.5,
and a few bug fixes.

#### Changed

- Recent releases of W2 version 4.5 added units to the parameter names in the
  W2 spreadsheet output file, such that what used to be Temperature is now
  listed as Temperature(C). Code was modified in W2Anim to ensure that a
  parameter read in as Temperature(C) is treated as if it were Temperature.
  This ensures compatibility with previous versions and other code in W2Anim.

#### Fixed

- Two small errors were found and fixed in the read_con() subroutine in
  the w2anim_w2subs.pl source file. The bugs prevented the correct reading
  of the contour and spreadsheet output file dates and frequencies for the
  csv version of the W2 control file. The code was modified to eliminate
  the problem.

- For the W2 Outflow Profile graph type, code was modified to ensure that the
  W2 layer outflow file was re-read if the number of skipped dates was
  changed when adding or changing the color-highlighting parameter. This
  is important because the master date array also must be regenerated if
  the number of skipped dates is changed.

#### Added

- A new section (and parameter) was added to the W2Anim initialization file
  (w2anim.ini) to allow the user to specify the preferred location of the
  directory used as temporary space. This directory is used when exporting
  certain image and video files. See the example w2anim.ini file in the
  new code package as well as the updated
  [User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
  for more information.

- Code was added to ensure that the default location used for temporary
  files was properly set. In addition, the code tests the new user-specified
  temporary path location as read in the w2anim.ini file to ensure that
  the directory exists and is readable and writable.


### [v0.9.6](https://github.com/sarounds/w2anim/releases/tag/v0.9.6) \[21-Aug-2023\]

This version is a minor but important update, with a few changes, fixes, and additions.

#### Changed

- The measured dam release-rate input file used for vertucal withdrawal
  zone graphs now can include top and bottom layer limits, so that the
  user can test the effects of limiting the vertical extent of a simulated
  selective withdrawal zone. See the updated
  [User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
  for more information.

- The read_con subroutine was modified so that W2 npt-type control files from
  both versions 4.2 and 4.5 are accommodated.

#### Fixed

- The read_con subroutine was modified slightly in how it reads the lines of
  csv-type W2 control files. Previous code would sometimes retain
  carriage-return characters in the values of some variables, and these
  code changes fix this problem.

- The pop-up windows showing goodness-of-fit statistics for time-series
  and for vertical profiles now get the immediate computer focus and are
  no longer resizable.

#### Added

- Code was added to ensure that the W2Anim main window is positioned fully
  on the user's screen when opening the program, starting a new project,
  changing the canvas size, or opening a saved project.


### [v0.9.5](https://github.com/sarounds/w2anim/releases/tag/v0.9.5) \[16-Jul-2023\]

This version includes some new features, such as allowing canvas sizes
larger than the user's screen size, allowing the user to change the size
of the main window, creating optional scroll bars when resizing the main
window, allowing saved projects to be opened from a double-click in the
File Explorer, and adding a W2Anim identifier icon.  See the updated [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Changed

- Previous versions did not allow the user to resize the main window with
  the drawing canvas via click-and-drag actions on the window edges
  and corners. The main window can now be resized via standard mouse
  click-and-drag operations. This changes the size of the window, but not
  the size of the drawing canvas. Optional scrollbars will automatically
  appear or disappear to allow full access to the drawing canvas. A maximum
  window size prevents expansion of the window beyond the extent of the
  drawing canvas.

- The Canvas Properties menu now allows the user to set a canvas width and/or
  height that is larger than the screen size. Scroll bars will be used to
  give access and visibility to parts of the canvas that would otherwise
  be off the screen. The menu also now honors the user-specified grid
  spacing when computing maximum screen sizes if Snap-to-Grid is turned on.

- Code was modified to fix a small bug that occurred when the date/time index
  for multiple graphs had been adjusted slightly, and the code for
  regenerating a graph was attempting to use the unadjusted date/time
  index, resulting in a graph with an erroneous "No Data" message. The
  fix was required for W2 profile graphs and W2 outflow graphs.

#### Added

- Saved W2Anim project files now can be opened from the command line that
  starts W2Anim, using a standard batch file as an aid. This also allows
  saved W2Anim project files to be opened in W2Anim via a double-click
  from a standard File Explorer. See the User Manual for details.

- A Windows icon file (w2anim.ico) for W2Anim has been created and is now
  used for window decoration (upper left corner) and in the Windows tray.
  A similar icon is available for use with other operating systems.
  For those who wish to modify their registry (Windows) or otherwise modify
  their system, the icon also can be associated with W2Anim *.w2a project
  files in the File Explorer. See the User Manual for details.


### [v0.9.4](https://github.com/sarounds/w2anim/releases/tag/v0.9.4) \[20-Jun-2023\]

This is just a bug-fix update. See the notes for previous versions for
more substantial feature additions and fixes.  The only update to the [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
was to update the version number and the Table of Contents.

#### Changed

- A problem was fixed in the code used to read CE-QUAL-W2 contour output
  files, such that in certain instances, data for the wrong parameter
  could be read.  Code was changed to fix the problem.


### [v0.9.3](https://github.com/sarounds/w2anim/releases/tag/v0.9.3) \[19-Jun-2023\]

This update adds a few new features for time-series graphs, some of which
allow W2Anim to better handle time-series datasets containing many years of
data.  Added a zoom toolbar and optional grid lines for time-series graphs.
See the updated [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Changed

- During object move operations, a more-common mouse cursor shape is
  now used.

- A few minor bugs in the interface were cleaned up.

- A few fixes were made to ensure that all dates were handled properly in the
  code. In some calculations, W2Anim uses a continuous date variable with
  a reference date of January 1, 1960. As a result, dates prior to the
  reference date are negative, and a few functions had to be modified to
  ensure that positive and negative date variables were handled identically.

- Large time-series datasets are now plotted in chunks of no more than
  500 points in a single object, so as to not bog down the GUI when changing
  dataset attributes. Long time-series datasets may be comprised of many line
  objects, but that behind-the-scenes handling is transparent to the user.

#### Added

- Two new Date/Time axis formats were added. A Year format now allows long
  time-series datasets to have usable axis labels. An example with a 145-year
  streamflow dataset was added to the W2Anim package to illustrate the use
  of this axis format. In addition to the Mon-DD axis format, a Mon-DD-YYYY
  axis format was added.

- Horizontal and vertical grid lines now may be added to time-series graphs
  from the new Grid tab of the Graph Properties menu. The width and color of
  the grid lines may be chosen, and horizontal or vertical grid lines may be
  activated separately. Grid lines appear at major axis tick mark locations.

- A Zoom Toolbar for time-series graphs was added. The toolbar has nine
  short-cut buttons to allow a user to quickly zoom in or out. Axis limits
  can still be controlled and fine-tuned from the Graph Properties menu,
  but the Zoom toolbar is a convenience.

- A new data-conversion type was added to allow for the conversion of flow
  data from cfs to kcfs (cubic feet per second to thousands of cubic feet
  per second). This option is for convenience, as the custom conversion
  could also make this conversion.

- A date range was added to the object information box for non-time-series
  graphs, which previously did not include that information.


### [v0.9.2](https://github.com/sarounds/w2anim/releases/tag/v0.9.2) \[28-May-2023\]

This update includes some fixes to better trap for missing values, updates
some existing code, and adds a few new features. See the updated [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Changed

- Code was changed in many places to better trap for missing values,
  particularly the missing water-surface elevations associated with a
  measured vertical profile file.

- When computing goodness-of-fit statistics between measured and modeled
  vertical profiles, the comparison between measured and modeled points
  was changed such that the comparison is made on the basis of depth if
  the measured profiles were provided with fixed depths. If the measured
  profiles were provided with fixed elevations, then the comparison between
  measured and modeled profiles still is done by comparing data at the
  same elevation. For measured profiles with fixed elevations, the modeled
  water-surface elevation now is used if a measured water-surface elevation
  is missing.

#### Added

- A gap tolerance was added for time-series graphs, such that date/time
  gaps exceeding the gap tolerance will break the line between adjacent
  points. When a data point has gaps exceeding the tolerance on both sides,
  the point is plotted with a small rectangle. The entire time series
  can be plotted with points rather than a line if the gap tolerance is
  sufficiently small, such as zero. The default gap tolerance is 2 days,
  and can be changed from the Graph Properties menu in the TS Data tab.

- In the Info pop-up box for all but time-series graphs, the depth range
  was added to accompany the elevation range of the data or the model
  results.

- W2Anim now recognizes W2 structure withdrawal output files as belonging
  to the "W2 Outflow CSV format" file type, and will attempt to extract
  parameter names when reading those files.

- For a time-series data file that is recognized to have a CSV format, W2Anim
  will try to extract a list of available parameter names from a
  comma-delimited header line that begins with "DateTime", "Date", or
  "Date/Time". For this type of time-series file, the following missing
  values are recognized: na, NA, -99, -999, or the empty string.

- W2Anim now recognizes and can read time-series output files from the
  [USGS Data Grapher](https://or.water.usgs.gov/grapher/). Missing values
  for this type of time-series file are expected to be "-123456E20".


### [v0.9.1](https://github.com/sarounds/w2anim/releases/tag/v0.9.1) \[11-May-2023\]

This update fixes a few bugs and adds an initialization file and the [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Changed

- Code was added to ensure that group tags would be preserved when graph
  elements were updated. The previous version sometimes lost the group tags
  when graphs were updated, causing a group move action, for example, to
  "splinch" the object and not move the parts together.

- Code was modified to ensure that axis limits for linked time-series
  graphs were initialized properly when certain units were chosen.

- Code was modified to catch an aborted action to create a PDF file.

#### Added

- Code was added to read a w2anim.ini initialization file.

- The first edition of the [User
  Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
  was completed.


### [v0.9.0](https://github.com/sarounds/w2anim/releases/tag/v0.9.0) \[24-Apr-2023\]

Version 0.9.0 was the original release.
