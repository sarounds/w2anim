# Change Log - The W2 Animator

All notable changes to The W2 Animator (W2Anim) will be logged to this file.


### [v1.6.0](https://github.com/sarounds/w2anim/releases/tag/v1.6.0) \[6-Feb-2026\]

Version 1.6.0 includes a utility to help the user search for, and download
data from, USGS time-series data-collection sites.  Users are encouraged
to update to this new version. More details are provided in the updated [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Added

- Added a new utility to help the user search for, and download data from,
  USGS time-series data-collection sites. This utility is accessed from
  a new "Data/Get USGS data" menu option, and makes use of the updated
  [USGS Water Data APIs](https://api.waterdata.usgs.gov/). Two new source
  files were added to the W2 Animator script package to implement this
  utility. The w2anim_datacodes.pl script file includes lists of USGS
  parameter codes and parameter names, state/territory codes, site-type
  codes, and the names and codes for HUC regions, subregions, basins,
  and subbasins. The w2anim_getdata.pl script file includes subroutines
  needed to find USGS time-series sites of interest and to download
  specific datasets. These new subroutines require the use of the Perl LWP,
  LWP::UserAgent, LWP::Protocol::https, Compress::Zlib, POSIX, URI::Escape,
  and Text::CSV modules, all of which ought to be part of the standard Perl
  distribution, but can be installed from CPAN if necessary. The new menu
  option for accessing USGS time-series data will not appear if a recent
  version of the LWP module is not available.

- Code was added to recognize and read time-series data files from USGS
  Water Data APIs that are in comma-delimited format as well as tab-delimited
  format. The assumption is that these files were downloaded using the
  new utility embedded in W2Anim.

- A subroutine was added to adjust a date (in YYYY-MM-DD HH:mm format) by
  a certain number of minutes (positive or negative). This is used to
  adjust USGS time-series data files to remove daylight saving time or to
  apply a user-selected time offset.

- A subroutine was added to convert a string into title case-- capitalizing
  the first letter of most words, but not minor words. This is used in
  the site name search for the new USGS data-download utility.

#### Changed

- The code that creates the main menu bar was moved up so that the menu bar
  would be created before the W2Anim initialization file is read. This is
  important because some menu entries may be modified by the initialization
  file.

- Additional missing-value indicators were added for measured vertical
  profile files and measured dam release rate files. The valid missing-value
  indicators are:  na, NA, -99, -999, and the empty string.

#### Fixed

- Code was modified to fix a small error in the initialization of the
  scrollbars for the main drawing canvas.



### [v1.5.0](https://github.com/sarounds/w2anim/releases/tag/v1.5.0) \[12-Dec-2025\]

In version 1.5.0, new annotation and drawing tools were added, including
curves and scribbles. Users now are able to draw complicated shapes,
such as river channels or more complex sketches, or provide on-the-fly
annotations during presentations.  Users are encouraged to upgrade
to this new version. More details are provided in the updated [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Added

- A "scribble" drawing type was added, which allows the user to freely
  draw shapes by hand. Points are added to the scribble as the user moves
  the mouse or stylus while holding down the left mouse button. Releasing
  the left mouse button ends the scribble, but the user can begin another
  immediately. Exit scribble mode by clicking the right mouse button.
  Co-linear (redundant) points are removed from the shape when the scribble
  is ended. Once created, the scribble and polyline object types are
  basically the same, except that the scribble is likely to have more points.

- A "curve" drawing type was added using cubic Bezier functions. The user
  specifies the endpoints for each cubic Bezier with clicks of the left
  mouse button, and double-clicks when done with the curve. Symmetric
  control points are assigned for the endpoint of each curve segment unless
  the user holds down the Shift key while assigning an endpoint location,
  in which case a corner type is assigned. The first and last endpoints
  on the curve also are assigned as corner types. Control point locations
  can be moved after the curve is created, at which time existing points
  may be deleted or new points may be added. To use the curve function,
  the user must install the Math::Bezier module from CPAN.

- Curves may be open or closed. Closed curves may be filled. Open curves
  may be split into two separate curves. Two curves also may be joined.

- Scribbles and polylines now may be joined to another scribble or polyline
  to form a single object.

- Because curves may be open or closed, two different objects had to be
  created for each curve. The open curve is a line object, whereas the closed
  curve is a polygon object as far as the Tk GUI is concerned.  The current
  form is shown, while its sister object is hidden.  When saving project
  files, only the visible form of the curve is saved to the project file,
  and the extra sister object is created upon opening that project file.

- As with many other objects, the new scribbles and curves can be resized,
  rotated, and flipped.

- Scribbles, polylines, and polygons may be simplified through a point
  resampling process.

- Scribbles, polylines, and polygons can be transformed into curves through
  a curve-fitting process that also allows points to be resampled and
  provides some options for the resulting curve endpoint types.

- If W2Anim can find the local copy of its User Manual (looking in the same
  directories where the W2Anim scripts are stored), then the Help menu
  will include a link to open that local copy of the W2Anim User Manual.

#### Changed

- The process of moving points in a polyline or polygon was changed so that
  once in Edit Points mode, the user can simply drag an existing point to
  a new location, rather than first right-clicking and selecting the Move
  Point option. That right-click menu now includes new options related to
  shape conversion and split options.

- Some subroutines were moved out of the w2anim_gui.pl source file (which
  has gotten rather large) and into the w2anim_utils.pl source file.

#### Fixed

- Some flags and bindings were added or modified to ensure proper
  functionality related to the editing of points for scribbles, polylines,
  polygons, and curves.

- In a number of places, code was added to ensure that an existing Object
  Information Box was refreshed if the box was providing information about
  an object that was being or had been modified.

- Code was added to ensure that variables and bindings were properly
  initialized when opening a file or starting a new project.

- Some code was fixed that did not properly find an object's anchor
  point when exiting Edit Points mode.


### [v1.4.2](https://github.com/sarounds/w2anim/releases/tag/v1.4.2) \[6-Nov-2025\]

Version 1.4.2 is an update to help fix potential issues with closing the program.
Users are encouraged to upgrade to version 1.4.2.  See the [change log
for version 1.4.0](https://github.com/sarounds/w2anim/releases/tag/v1.4.0)
for recent major changes. No substantive changes were made to the [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Fixed

- Code was added to ensure an efficient exit from the program when the user
  decides to close the program by clicking on the X in the upper right corner
  of the main window. A delay may have occurred with previous versions.


### [v1.4.1](https://github.com/sarounds/w2anim/releases/tag/v1.4.1) \[6-Nov-2025\]

Version 1.4.1 is an update to fix a problem that was introduced in version
1.4.0. Users are encouraged to upgrade to version 1.4.1.  See the [change log
for version 1.4.0](https://github.com/sarounds/w2anim/releases/tag/v1.4.0)
for recent major changes. No substantive changes were made to the [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Fixed

- A coding error was fixed in the build_profile_match_list subroutine. This
  error did not always manifest itself, but could cause loop issues that
  would keep the program from responding.


### [v1.4.0](https://github.com/sarounds/w2anim/releases/tag/v1.4.0) \[27-Oct-2025\]

This version is a substantial upgrade with many new features and a new
graph type for plotting a matrix of static W2 Vertical Profile plots.
Users are encouraged to upgrade to this new version. More details are
provided in the updated
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Added

- Vertical profiles of modeled parameter values can now be interpolated,
  rather than just showing a uniform value for each layer in the model grid.
  The user can show a vertical profile line as a stairstep for each model
  layer, or can interpolate from one layer to the next; this is an option
  for the W2 Vertical Profile plots and for the new W2 Vertical Profile
  Matrix plots. Similarly, the color profile can be interpolated in two
  new ways for W2 Vertical Profile and Colormap graphs, W2 Vertical Profile
  Matrix plots, W2 Longitudinal Slice graphs, and W2 Outflow Profile graphs.
  The Graph Properties menu now has a Profile tab for these graph types,
  which allows the user to edit some of these profile properties.

- A new W2 Vertical Profile Matrix plot option was added. This matrix plot
  consists of a user-specified number of rows and columns showing specific
  date/time instances derived from a separate W2 Vertical Profile graph.
  The matrix plot is created from the Reference Data submenu of a W2
  Vertical Profile graph, once measured reference profiles are added to
  that profile graph. The user can specify the date/times of interest from
  among the available dates with measured profiles that match the dates
  of modeled profiles within a user-specified tolerance. The user can
  arrange the graphs in the matrix as they desire, or sort them by date.
  Blank spaces can be placed in the matrix. Up to 15 rows and 25 columns
  can be placed in the matrix of profile plots, for a potentially large
  number of comparison plots. The user can modify the matrix as they please
  after it is first created. Color highlighting of the modeled profile in
  the background is optional, just as it is for the animated W2 Vertical
  Profile graph. Goodness-of-fit statistics can be added to all of the
  individual plots in the matrix. The user can specify the graph location
  and many attributes for the fit statistics and the date/time label for
  each graph in the matrix.

- The measured reference profiles displayed in W2 Vertical Profile graphs
  and W2 Vertical Profile Matrix plots now allow for some small amount of
  user control over their line width and symbol size. The Graph Properties
  menu now allows the user to modify the symbol size, line width, and line
  color for the measured profiles, as well as the line width, line color,
  and interpolation style for the modeled profile.

- Linked objects for things like water-surface elevations and release
  rates can now be created from W2 Outflow Profile graphs and from W2
  Vertical Profile graphs.

- The Animation toolbar was modified to allow the user to jump from one
  date/time with a measured vertical profile in a W2 Vertical Profile
  graph to the next date/time with a measured vertical profile. This is
  done by holding down the Shift key while left-clicking the Forward or
  Backward button on the Animation toolbar. A keyboard-only alternative
  also is possible. This functionality is not enabled unless a W2 Vertical
  Profile graph is present that also has reference measured profiles loaded.

- The Animation toolbar also was modified to allow the user to skip a
  certain number of entries in the master date/time list during animation,
  in case so many dates are available that the animation appears to move
  slowly in time relative to dates of interest, even when the time delay
  is small or zero. Holding the Shift key down while left-clicking on the
  Faster or Slower buttons on the Animation toolbar will change the skip
  date value (default is 1).  A keyboard-only alternative also is possible.
  This option is only available when at least 100 frames are available
  in the animation.  If the time interval between animation dates is
  constant, then an animation of model output at hourly output intervals,
  for example, can be sped up to show only animated results at noon, say,
  by starting the animation at noon and setting the skip date to 24.

- A new Text Link object was added, such that a text object can display the
  value of a time series from an independent external time-series file
  that is not linked to any other object or graph in the current project.
  This Text Link object will change its displayed value as an animation
  proceeds.  The external time series file does not affect the date/time
  series for the animation of W2Anim graphs, but matches of the date/times
  in the external file will be displayed as an W2Anim animation proceeds.

- Added a new subroutine to help crop (or clip) vertical profile plots at
  plot boundaries.

- Added a new subroutine to format date/times in a variety of formats
  and generalized some existing subroutines to include additional formats.

#### Changed

- Code was modified to ensure that graphs that are only in the process of
  being created are ignored if the user initiates a hard exit from W2Anim
  or when clearing the canvas to start a new project.

- When clearing the canvas to start a new project, or when confirming an
  exit from the current project when changes have been made relative to
  the saved file, the user interface now can redirect the user to the
  dialog box for saving a file.

- A few changes were made to the code for displaying X and Y coordinates
  when hovering the mouse over the new W2 Vertical Profile Matrix plots.

- Code was added in an attempt to adjust the background of the text entry
  field when editing text properties, to account for a text foreground
  color that is too similar to the standard background color for the text
  entry field.

- The make_axis subroutine was modified to allow for the minimum and/or
  maximum tick label to be omitted, for the purpose of W2 Vertical Profile
  Matrix plots. Similarly, axis and tick labels can be omitted altogether
  when necessary.

#### Fixed

- The code that sets the name of one of the autosave files was fixed.

- The code that deletes stale copies of autosave files (more than 5 days old)
  was fixed.

- Modified the subroutine that reads W2 control files such that the code is
  better able to handle missing fields for certain output file frequencies.
  This sort of information is used to convey information to the W2Anim user.
  Some code was changed in the GUI for menus that use this information.

- In the subroutine that calculates W2 grid elevations, code was added to
  ensure that elevations are computed for the tops and bottoms of every
  W2 model layer.  In the past, the elevation for the very bottom of the
  last layer was not computed, but that is needed when a W2Anim plot shows
  the bottom of the grid.

- In the subroutines that read W2 cell widths from bathymetry files, code
  was added to ensure that the widths for layer 1 were set equal to those
  from layer 2, just as is done in the W2 model.  This is only important
  if modeled water levels ever reach into layer 1.

- In a few subroutines that calculate outflows as a function of model layer,
  the code was modified to ensure that flows for layer 1 were properly
  initialized and computed, to ensure accurate results if water ever
  reaches into that layer.

- When loading, hiding, showing, or deleting reference data for W2 Vertical
  Profile plots, code was added to ensure that the animation toolbar
  and the Graph Properties menu, and sometimes the Object Info menu,
  are rebuilt if they already exist.

- When flipping an object horizontally or vertically, code was modified to
  try to move a user-defined anchor point associated with a specific
  control point that also is being moved (flipped) on that object.


### [v1.3.3](https://github.com/sarounds/w2anim/releases/tag/v1.3.3) \[28-May-2025\]

This minor version includes fixes to several small bugs, mostly related to the
W2 Outflow Profile graph with color highlighting. Users are encouraged to upgrade
to this new version. No substantive changes were made to the
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Fixed

- The WDO output dates and frequencies were not being read properly from
  the CSV format of the W2 control file, which affected the display of the
  WDO output frequency in a menu for the W2 Outflow Profile graph. This
  bug was fixed.

- When using the Tecplot format of the W2 contour output file for color
  highlighting in a W2 Outflow Profile graph, a bug in the code prevented
  the W2 contour output file from being recognized properly. The code was
  modified to fix this error.

- When updating an existing W2 Outflow Profile graph in W2Anim to add color
  highlighting, especially when doing so after saving the W2Anim project
  and starting from the saved project file, some graph parameters were
  not being set and saved properly when trying to add color highlighting.
  The code was modified to properly set these graph parameters.


### [v1.3.2](https://github.com/sarounds/w2anim/releases/tag/v1.3.2) \[18-Dec-2024\]

This is another minor release with a couple of small fixes to guard against
file name differences caused by the operating system's sensitivity to upper
or lower case letters. A small fix also was made to streamline the code used
when exiting the program. See the [change log for version
1.3.0](https://github.com/sarounds/w2anim/releases/tag/v1.3.0) for recent major changes.

#### Changed

- Made two small changes in the code that compares W2Anim project file names
  to ensure that case-tolerant systems like Windows are handled properly.

- Added a small fix to ensure that the code used to confirm the user's exit
  from the program did not result in a circular subroutine call.


### [v1.3.1](https://github.com/sarounds/w2anim/releases/tag/v1.3.1) \[17-Dec-2024\]

This minor version has one small change to fix a potential case comparison
issue on operating systems like Windows that are tolerant to case differences
in file names. See the [change log for version
1.3.0](https://github.com/sarounds/w2anim/releases/tag/v1.3.0) for recent changes.

#### Changed

- Made one small change in the code that compares W2Anim project files
  to ensure that case-tolerant systems like Windows are handled properly.


### [v1.3.0](https://github.com/sarounds/w2anim/releases/tag/v1.3.0) \[15-Dec-2024\]

This version represents a substantial upgrade with new features and code
fixes, including a new graph type to plot and animate W2 water levels along a
longitudinal reach, the addition of animated datelines on time-series plots,
more user control over tick marks, the addition of borders and fills for
legends of time-series graphs, an autosave feature, and a recent-file list.
Users are encouraged to upgrade to this new version. More details are
provided in the updated
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).

#### Added

- A new W2 Water Levels graph type was added. This animated graph uses
  W2 results from either the contour, vector, or water-level output file to
  show a longitudinal water-level elevation plot for a user-defined reach. An
  optional segment axis can be displayed along with a distance X axis.
  Segment and branch boundaries can be displayed along with layer boundaries.
  Water levels can be shown either as flat stair steps for each segment,
  stair steps with the branch slope, or interpolated. This graph type is
  useful for evaluating branch slopes, evaluating the effects of wind on
  water levels, and for finding anomalies in the computed water-surface
  elevations.

- The animation toolbar now includes a Repeat toggle button. When turned
  on, the Repeat function will allow the animation date to cycle from
  the last date to the first date when playing in the forward direction,
  or from the first date to the last date when playing in reverse.

- The user can now control how tick marks are plotted on the primary axis and
  the opposite axis of each graph. Previous W2Anim versions plotted all
  tick marks on the outside of the primary axis only. Tick marks now can be
  plotted on the outside or inside, as a cross, or omitted altogether. Users
  specify the tick mark style separately for the primary and opposite axes.

- Time-series graphs and linked time-series graphs now can include an
  optional vertical dateline denoting the current animation date when
  other graphs are animated. The user can turn this feature on or off and
  also control the line color from the X-axis tab of the Graph Properties
  menu. This feature was also added for Profile Colormap graphs and
  W2 Profile Colormap graphs, which previously had the dateline always
  turned on.

- Legends for time-series graphs now can be given a fill color and/or
  a border.  The legend fill and border are in front of any user-defined
  grid lines and in front of the vertical dateline, but behind the axes
  and any plotted datasets.

- The File menu now includes a Recent menu that allows the user to quickly
  open one of up to fifteen recently opened W2Anim project files, or to
  clear the list. Entries are saved in the w2anim_recent.txt file that is
  stored in the W2Anim script home directory.

- W2Anim now includes an autosave feature, accessed from the File/Autosave
  menu. This feature is off by default, but the user can enable an autosave
  to occur every 1, 2, 3, 4, 5, 10, or 20 minutes.  Each instance of The W2
  Animator will be associated with two unique autosave file names, using
  the convention "_autosaveXXXXX.w2a" and "_autosaveXXXXX_2.w2a" where
  the XXXXX is a random number generated when the program starts. Autosave
  files may be found in the temporary directory, which is shown under the
  Help/Configure menu. The first autosave file is the one that is generated
  whenever the autosave routine is scheduled to run. When that file is
  created, it is compared to any pre-existing autosave file to determine
  whether any changes had been made. If any changes had been made, then
  the previous (different) autosave file is saved as the second autosave
  file. This way, the most-recent two distinct and different autosaved
  files are available to the user. The first may be loaded (when it exists)
  by choosing the "Revert, recent" option from the File/Autosave menu.
  The second may be loaded (when it exists) by choosing the "Revert,
  previous" option from the File/Autosave menu. Either may be loaded
  by simply opening the appropriate file from the temporary directory.
  These autosave files, if present, will be deleted if W2Anim exits normally,
  and stale autosave files will be removed upon program startup if they
  are more than 5 days old. Autosave operations are not allowed during
  animation, during the export of output, while saving a project file,
  or while opening a previously saved project file.

- When the user exits the program either by using the File/Exit menu option
  or by trying to close the main window using the operating system's window
  frame decorations (a big X in Windows), W2Anim now will try to determine
  whether the current project has been saved or might need to be saved. If
  such a need is determined to exist, then the user will be asked whether
  they wish to save the project before exiting.

- When the user tries to start a new project with a clean canvas by using
  the File/New option, W2Anim now will try to determine whether the current
  project has been saved or might need to be saved. If such a need is
  determined to exist, then the user will be asked whether they wish to
  save the project before clearing the canvas and starting a new project.

- When the user tries to open a saved project using the File/Open menu option
  or the File/Recent menu option or the File/Autosave/Revert menu options,
  W2Anim now will try to determine whether the current project has been
  saved or might need to be saved. If such a need is determined to exist,
  then the user will be asked whether they wish to save the project before
  clearing the canvas and opening a saved project.

- If an autosaved W2Anim project file is loaded, the program will now
  remind the user that they have loaded an autosaved project file and that
  it might be wise to save the project under a new name.

#### Changed

- When reading a CE-QUAL-W2 Water Level output file (typically wl.opt
  or wl.csv), W2Anim now will recognize a -999 value as a missing value
  for the new W2 Water Levels animated plot. New versions of CE-QUAL-W2
  plan to use a -999 value as a code to denote inactive segments, whereas
  old versions of the model report stale water-level values for inactive
  segments. The W2Anim subroutine that reads W2 Water Level output files may
  attempt to detect the presence of inactive segments in certain situations
  (no -999 values, branch slope of zero, upstream head segment of zero).

- The Graph Properties menu was modified to make space to add input
  controls for tick mark specifications, for vertical datelines (for
  certain graph types), and for legend box outlines and fill colors (for
  time-series plots).

- A distance axis base value was added for W2 Time/Distance Maps, W2
  Longitudinal Slice plots, and W2 Water Levels graphs.  The distance
  base value is the distance value for the downstream-most part of the
  user-specified longitudinal reach.  Previously, the distance axis minimum
  value was used for this base value, but that prevented the user from
  changing the minimum distance value to zoom in on the distance axis for any
  reach that did not include the most-downstream segments.  By separating
  the base value from the minimum value, users now can effectively zoom in
  on the distance axis.  The Graph Properties menu was changed to include
  the base value for the distance axis for these graph types.

#### Fixed

- Code was modified to ensure that the date index array for animation was
  rebuilt when an animated graph was deleted. The updated code is more
  robust in checking whether an update is required.

- The menu for editing object links was fixed to ensure that the linked
  object was filled and that the fill status and fill color could not be
  changed, as the fill color is controlled by the linked source graph.

- When a linked color scheme affects another graph, the height of the
  cells in the color key legend is now set to try to preserve the total
  height of the color key.

- The code for creating the segment axis was modified to ensure that axis
  placement was appropriate for the segment axis and the X distance axis
  when user-specified tick marks are modified.


### [v1.2.3](https://github.com/sarounds/w2anim/releases/tag/v1.2.3) \[10-Oct-2024\]

This version represents a minor modification to fix an issue with the new
global date limits feature. An update is recommended.

#### Fixed

- Code was modified slightly to fix an issue with the global date limits
  feature.  When a change to an animated graph caused the global dates list
  to be updated, the global date limits (if present) were not applied to
  the updated global dates list. The issue has been fixed.


### [v1.2.2](https://github.com/sarounds/w2anim/releases/tag/v1.2.2) \[7-Oct-2024\]

This is a substantial code update, in that a number of new features were
added and several issues were fixed. Please update to this version. See
the list below and see the
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
for more details.

#### Changed

- When very large output files are used to create W2 Longitudinal Slice
  plots, Perl may run out of memory when creating the slice images
  for each date. Running out of memory in this way is rare, but it can
  happen. Therefore, the code was edited in a number of locations to
  remove unnecessary variables and to un-define arrays and hashes that
  were no longer needed, in order to use less memory.

- For W2 Profile graph objects, the Fit Statistics Table menu entries
  available when right-clicking over the graph (one for interpolated profiles
  and one without interpolation) were consolidated into a separate menu
  from a single "Fit Statistics Table" menu option. That new menu allows
  the user to specify whether the model profiles should be interpolated
  to the measured elevations or depths, whether monthly goodness-of-fit
  statistics should be computed, and whether a date restriction should be
  placed on the computation of such statistics. In this way, goodness-of-fit
  statistics can be computed for any user-specified period.

- The subroutines that scan W2 Contour and Vector output files were modified
  to allow them to return the first and last dates from those files,
  which is useful in helping the user to set date restrictions for W2
  Longitudinal Slice plots or to set global date limits for animation.

#### Fixed

- Code was modified to ensure that a few more menus, when initially formed,
  are placed completely on the visible part of the screen.

- Code for the Graph Properties menu was modified because the original code
  had omitted to set the saved value of the first labelled X-axis tick
  mark for W2 Longitudinal Slice plots.

- Code was modified to ensure that a user-supplied major tick increment of
  zero would be reset to "auto" and thereby not cause an infinite loop.

- A few minor layout issues were fixed or updated in several menus.

- A potential problem matching modeled and measured dates for the computation
  of profile goodness-of-fit statistics was fixed.

- Several changes were made to ensure that slight discrepancies in dates did
  not prevent those dates from being properly recognized while objects
  are being animated. When several graphs with different data files are
  present on the canvas, the master date/time array is configured such
  that dates that are within 5 minutes of one another are deemed redundant
  and eliminated. This means that the code must search within 5 or so
  minutes of the present date/time index (when animating) to see if data
  are available for any animated graph object. A few of the subroutines
  did not employ that nearby search, and so were updated.

- A typographical error associated with the initial code for the placement
  of segment numbers on the segment axis of a W2 Longitudinal Slice plot
  was fixed.

#### Added

- The Tecplot version of the W2 Contour output file includes some outputs
  that are not present in the original W2 Contour output file format. Code
  changes were made to allow the W2Anim user to choose the Density and
  Habitat outputs that are included in the Tecplot version of the W2
  Contour output file.

- A feature was added to the W2 Longitudinal Slice plots to allow their
  date range to be restricted to a user-defined period. This is important
  for very large data files or for large plots (many pixels) with many dates
  to animate. In such instances, Perl may run out of memory while creating
  the slice images for each date/time index in preparation for animation.
  This is a rare problem, but if it occurs, the user can now restrict the
  date range for a W2 Longitudinal Slice plot, either upon first plot
  creation or while changing plotting conditions later. This new date
  restriction option means that several new parameters may need to be
  saved to the W2Anim project file. See the User Manual for more details.

- A global "date limit" feature was added to W2Anim to make it easier for
  the user to animate the objects on the canvas only for a desired time
  period. Previously, the global dates list included date indices for all
  animated graphs. Now that the W2 Longitudinal Slice plots can have date
  restrictions, it is possible for many animated graphs on the canvas
  to have different start and stop dates, even if they are derived from
  the same W2 output files. It is a convenience to the user, therefore,
  to allow the specification of global date limits to control the dates
  included in the animation. A "Date Limits" menu entry was added to
  the Edit/Preferences menu and to the pop-up menu that appears when
  right-clicking on the drawing canvas. This menu option only appears in
  the right-click menu and is only active under the Edit/Preferences menu
  when at least one animated graph is present on the canvas. The presence
  of global date limits will result in a new section in the W2Anim saved
  project file. See the User Manual for an explanation of the options
  associated with the Date Limits menu.

- The computation of goodness-of-fit statistics, either for vertical profiles
  or for time-series plots, now includes an optional date range so that
  these statistics can be computed for user-defined time periods. The menu
  options also now allow the user to specify whether monthly statistics
  also are wanted.


### [v1.2.1](https://github.com/sarounds/w2anim/releases/tag/v1.2.1) \[27-Aug-2024\]

Version 1.2.1 is a quick fix after the recent release of version 1.2.0. Just
a couple of changes were made, and the
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
was updated.

#### Changed

- Code was modified to safely circumvent any problems with systems that
  do not have the File::Find::Object module installed. That Perl module is
  used to quickly help search for and find the helper programs, and it has
  advantages over the standard File::Find module.  If the File::Find::Object
  module is not installed, the code will fall back to use the File::Find
  module. The File::Find::Object module can be installed with the following
  command from a Perl command prompt:
```
  cpanm File::Find::Object
```

- The maximum match tolerance for linked statistic objects for W2 Vertical
  Profile graphs was increased from 120 to 180 minutes. The default remains
  at 10 minutes.


### [v1.2.0](https://github.com/sarounds/w2anim/releases/tag/v1.2.0) \[25-Aug-2024\]

Version 1.2.0 is a major update, in that a number of important changes
were made to add new features, fix a few potential problems, and enable
easier startup and initialization.  Please upgrade to this version.
The specific changes, fixes, and additions are noted below. See the updated
[User Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf)
for more details.

#### Changed

- Several changes were made to allow W2Anim to be started from a command
  prompt in a more flexible and robust fashion. W2Anim now determines the
  path to its scripts in a way that should be more reliable, thus ensuring
  a more dependable start.

- When W2Anim starts up, one of its first tasks is to search for and find
  the locations of the Ghostscript and FFmpeg helper programs, if they are
  installed on the local system. Previously, W2Anim would perform a more
  extensive search for these programs if they were not found initially in
  an expected location, and that search could take several minutes and be
  confusing to the user as a sluggish start. Now, only a cursory search for
  the helper programs is performed, and the user is alerted if these helper
  programs are not found. An option to perform an automated search is then
  provided as an option to the user.  The File::Find::Object module is now
  used for such searches because it is faster and provides options to exit
  early; that module hopefully is part of the standard Perl distribution.

- The vertical profile goodness-of-fit statistics calculation was modified
  to allow the modeled profile to be vertically interpolated to match the
  depth or elevation of the points in a measured profile, if the user asks
  for an interpolated match.

- In order for W2Anim to properly handle sloping model grids and accurately
  represent the elevation of the bottom of each model segment, the relevant
  model bathymetry file(s) must now be read by W2Anim, even when using
  W2 Contour and Vector (w2l) output files that include similar, but less
  reliable, information.  The user interface was updated to include this
  new requirement.

- All pop-up windows in the W2Anim program now check their size and location
  to ensure that the entire pop-up window is shown on the screen. Previously,
  some part of the pop-up window or menu might have been initially located
  off of the user's screen.

- The minimum user-defined cell height for each color in a color scheme
  legend was decreased from 3 to 2 pixels.

- The maximum match tolerance for vertical profiles was increased from
  120 to 180 minutes, but the default remains at 10 minutes.

- Linked text objects now use the default slant characteristic (italics
  or normal).

- In the absence of data, linked text objects now show an "na" value.

#### Fixed

- The match tolerance algorithm for time-series datasets and for vertical
  profile dataset comparisons was updated to recognize that such a
  date/time comparison must take into account the minute (60) and hour
  (24) branch cuts.  The previous algorithm was too simple and unreliable.

- Changes were made to ensure that W2Anim accurately tracks and plots
  the bottom elevation of each model segment in W2 graph types. W2Anim now
  recognizes situations for sloped branches when the surface layer may be
  temporarily located below the segment bottom. The water surface should
  still be above the real segment bottom in such cases, and W2Anim now
  accurately plots the segment bottom elevation. This fix is particularly
  important for W2 Longitudinal Slice plots, but is relevant for all W2
  graph types.

- When plotting rectangular color regions to an image (such as for vertical
  profile plots or longitudinal slice plots or time/distance maps), it turns
  out that single-pixel horizontal or vertical line plotting or individual
  pixel plotting was not supported with the same syntax by the toolkit.
  Changes were made to the code to ensure that these special cases are
  now handled properly.

- Code was modified to ensure that when a W2 model branch is sloped,
  the W2 Longitudinal Slice plots reflect that slope. Previously, the
  code was configured to handle only zero-slope branches. The updated
  longitudinal slices for sloped branches are now more accurately visualized.

- When many branches or waterbodies are used in a W2 Time/Distance Map
  or a W2 Longitudinal Slice plot, many input files may be required. The
  user interface now employs a vertically scrolled menu to ensure that
  the list of required inputs does not push the bottom of the menu off of
  the screen.  The same type of optionally scrolled menu is now used for
  the list of time-series datasets in the graph properties menu.

- A rare issue with a date/time axis label that might be double printed
  was fixed.

- In the code that scans a W2 vector output file, a problem with the
  specification of the file name was fixed.

#### Added

- Two new lines were added to the w2anim.ini initialization file to allow
  the user to set the paths for the Ghostscript and FFmpeg helper
  programs. For systems in which those programs reside in non-standard
  locations, this will help W2Anim to find those programs more quickly.
  If either program is not installed, an "off" entry can be substituted
  for the program path.

- The w2anim.ini initialization file can now be saved from the
  Edit/Preferences menu.

- The numeric legend plotted with a color scheme previously was set using
  only the minimum and maximum values along with the number of color steps
  used in that color scheme. In this version of W2Anim, the user has an
  option to set the scale increment for the legend. This does not affect
  the values associated with the boundaries between adjacent color steps,
  but does allow the user to more cleanly set the numeric legend entries
  that are plotted next to the color scale. The original behavior is
  retained by setting the scale increment to "auto".

- Vertical profile goodness-of-fit statistics can now be computed using
  (1) a vertically interpolated model profile or (2) the original method
  that simply finds the model layer in which the measured point resides.

- Vertical profile goodness-of-fit statistics are now reported both in
  aggregate based on the pairs of points compared and also as mean statistics
  averaged over the number of measured vertical profiles compared.

- When comparing W2 Vertical Profile plots to measured profiles, linked
  goodness-of-fit text objects can now be created, and those linked statistic
  objects will be updated for each new date/time as the W2 Vertical Profile
  graph is animated. The linked statistic objects can be moved and grouped
  just like other objects, and their properties can be modified.

- For W2 models that are run using time zones that do not correspond to the
  local standard time, all of the W2 graph types in W2Anim can now
  be configured with a time offset (default: +00:00) so that the model
  output can be changed to the local standard time. For example, if the
  model was run based on a time standard of UTC but the waterbody is
  located in the Pacific Standard Time zone, then a time offset of -08:00
  would be used to convert the model date/time to a local standard time
  of PST. (W2 models typically are run in standard time, or at least do
  not deal with any changes related to daylight saving time.)  Similarly,
  any W2-type time-series input files now also have the option to specify
  a time offset when being read.

- Grouped objects can now be deleted as a group, such that all of the
  members of the group are deleted, as opposed to just removing the group
  tag (ungroup).

- A segment axis option was added to the W2 Longitudinal Slice graph type.
  In the Graph Properties menu, the segment axis options are under the
  "S Axis" tab. A segment axis can replace the X distance axis or can be
  placed above or below the X distance axis. Optional vertical grid lines
  can be placed at segment major increments, and optional vertical grid
  lines can be placed at branch boundaries.


### [v1.1.2](https://github.com/sarounds/w2anim/releases/tag/v1.1.2) \[19-Apr-2024\]

This is a minor update to fix a problem in the calculation of goodness-of-fit
statistics for a time-series comparison.  Users are recommended to upgrade.
The only update to the user manual was to update the version number.
Please see the CHANGELOG for previous versions for more substantive
recent changes.

#### Fixed

- The calculation of goodness-of-fit statistics for a time-series comparison
  (as opposed to a vertical profile time-series) was updated to ignore any
  missing values that may be present in either dataset. Prior to this fix,
  missing values in either dataset would lead to incorrect goodness-of-fit
  calculations.


### [v1.1.1](https://github.com/sarounds/w2anim/releases/tag/v1.1.1) \[12-Apr-2024\]

This is a minor update, just to fix a small bug in the change-parameter
menu of the W2 Time/Distance Map graph. Users are recommended to upgrade.
The only update to the user manual was to update the version number.
Please see the CHANGELOG for the previous version for more substantive
recent changes.

#### Fixed

- Fixed a small bug in the change-parameter menu for the W2 Time/Distance
  Map graph.  The previous version could report an error when no error
  existed in the selection of the parameter divisor.


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
