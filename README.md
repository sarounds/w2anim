# W2Anim - The W2 Animator

A Perl script to visualize CE-QUAL-W2 model results as well as limnological
vertical profiles and time series data.


## Current Version

Version 1.4.0 [27-Oct-2025] is the current version.


## Overview / Description

The W2 Animator is an interactive Perl script that allows the user to
explore and visualize output from the [CE-QUAL-W2](https://cee.pdx.edu/w2)
two-dimensional flow and water-quality model as well as measured data from
limnological profiles and time series.  Several of the visualizations
can be animated to view data and model results over time.  All graphs
are created on a "drawing canvas" that can be annotated with text, shapes,
lines, and images.  Everything on the canvas can be exported as encapsulated
PostScript, and optionally in PDF or raster image formats or as a video file.

A number of different graph types are supported, including:

- Vertical profiles of measured parameters over time,
- Vertical profiles of model results over time,
- Vertical profile matrix plots of modeled and measured parameters,
- Longitudinal slices of model results through the model domain, over time,
- Modeled water-level plots for a longitudinal reach over time,
- Time/distance maps of model results,
- Vertical withdrawal zones at dam outlets, from measured data,
- Vertical withdrawal zones from model output,
- Measured time-series data, and
- Modeled time-series data.

More graph types will continue to be added with future releases.


## Installation and Usage

The W2 Animator is written in Perl with the Tcl/Tk toolkit, and therefore
requires the user to have both Perl and Tcl installed with the proper
modules.  See the [Installation Notes](INSTALLATION.md) document for
detailed instructions to install these packages and the required modules.

Visualizations from The W2 Animator can be exported natively in encapsulated
PortScript format.  To export visualizations in PDF format or in several
types of raster image formats (PNG, GIF, JPG, BMP, PPM, TGA, TIFF), an
independent helper program such as Ghostscript must also be installed.
Similarly, to export video files in several formats (AVI, FLV, GIF, MOV,
MP4), an independent helper program such as FFmpeg must also be available.
See the [Helper Program Installation Notes](HELPER_APP_NOTES.md) document
for detailed instructions for obtaining and installing these independent
helper programs.

Once Perl and Tcl are installed and any helper programs are available, the
[latest W2Anim package](https://github.com/sarounds/w2anim/releases/latest)
may be downloaded from this site and unzipped to any appropriate location
on the user's computer.  Running The W2 Animator is as simple as starting
the w2anim.pl script.  Windows users may double-click on that script file
from the Windows File Explorer, or a Perl command window may be started
and the w2anim.pl script initiated from there.


## Support

Documentation for The W2 Animator is available in the form of a [User
Manual](https://github.com/sarounds/w2anim/blob/main/src/user_manual/W2Anim_manual.pdf).
The manual will be updated as new features are added.

Questions about The W2 Animator may be directed to the primary author
(Stewart Rounds) at <roundsstewart@gmail.com>.

Developing The W2 Animator as a data visualization tool has been
a hobby and obsession, and I am happy to make it available for free
to the W2 user community.  Although this software is absolutely free
of charge, it is my hope that some users of The W2 Animator, perhaps
particularly those who may be using it as part of a business, will
choose to independently support higher education in some fashion.
Two worthy funds that might be considered are:

- The *CE-QUAL-W2 Model Development Fund (#8610011)* at the
  [Portland State University Foundation](https://giving.psuf.org/), and

- The *Stewart Rounds & Bernadine Bonn Scholarship Fund*
  at the [Oregon State University Foundation](https://give.fororegonstate.org/).


## Contributing

If you have ideas for improvement, please let me know.  If you wish to
join this project, send me an email.


## Authors and Acknowledgment

All development on The W2 Animator up to this point has been done by the
primary author, Stewart Rounds.  The author appreciates all of the work
on the Perl base code and various Perl modules by the Perl community.

The author also acknowledges and is thankful to those who have developed
useful color schemes that are applied in this program.  Several of the
color schemes used in The W2 Animator were developed by or [described
by](https://www.kennethmoreland.com/color-advice/) Kenneth Moreland. Seven
of the perceptually uniform color schemes are part of the [Scientific
colour maps](https://www.fabiocrameri.ch/colourmaps/) package produced by
Fabio Crameri.  All color schemes used in The W2 Animator are free for
use and redistribution, and their known developers or copyright holders
and licenses are listed here:

- **CoolWarm**:  Developed by Kenneth Moreland
  ([public domain; CC0 creative commons](https://creativecommons.org/publicdomain/zero/1.0/))

- **Viridis**:  Developed by Eric Firing
  ([public domain; CC0 creative commons](https://creativecommons.org/publicdomain/zero/1.0/))

- **Plasma**:  Developed by Stefan van der Walt and Nathaniel Smith
  ([public domain; CC0 creative commons](https://creativecommons.org/publicdomain/zero/1.0/))

- **Inferno**:  Developed by Stefan van der Walt and Nathaniel Smith
  ([public domain; CC0 creative commons](https://creativecommons.org/publicdomain/zero/1.0/))

- **BlackBody**:  Developer unknown; scheme has been in use for decades
  (no known claims of intellectual property)

- **Batlow**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **Bam**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **Cork**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **Roma**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **Vik**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **Oslo**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **grayC**:  Developed by Fabio Crameri
  ([MIT license](https://choosealicense.com/licenses/mit/))

- **Kindlmann**:  Developed by Kindlmann, Reinhard, and Creem
  (no known claims of intellectual property)

- **Extended Kindlmann**:  Based on scheme developed by Kindlmann, Reinhard, and Creem
  (no known claims of intellectual property)

- **Turbo**:  Copyrighted by Google, LLC.
  ([Apache license, version 2.0](https://www.apache.org/licenses/LICENSE-2.0))

- **Jet**:  Developer unknown.  Used in matplotlib.
  ([matplotlib BSD-compatible license](https://matplotlib.org/stable/users/project/license.html))

- **CubeYF**:  Developed by Matteo Niccoli
  ([free use and redistribution](https://mycartablog.com/2013/03/06/perceptual-rainbow-palette-the-goodies/))

- **Cube1**:  Developed by Matteo Niccoli
  ([free use and redistribution](https://mycartablog.com/2013/03/06/perceptual-rainbow-palette-the-goodies/))


## License

This program is free software; you may redistribute it and/or modify it
under the terms of the [GNU General Public License](LICENSE) as published
by the Free Software Foundation, either version 3 of the License or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
[GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html)
for more details.


## Citation

The W2 Animator may be cited through the software or the user manual. Examples are:

- Rounds, S.A., 2025, The W2 Animator, version 1.4.0: Software
  available from GitHub repository, accessed October 27, 2025, at
  https://github.com/sarounds/w2anim/.

- Rounds, S.A., 2025, The W2 Animator User Manual (version
  1.4.0): GitHub website, 141 p., accessed October 27, 2025, at
  https://github.com/sarounds/w2anim/.


## Project Status

Under active development.
