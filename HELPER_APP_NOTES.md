# HELPER PROGRAM NOTES 

Two programs may be used by The W2 Animator (W2Anim) to help with the
creation of image and video files:

- Ghostscript is used to create PDF and PNG files from Encapsulated
  PostScript, and

- FFmpeg is used to create AVI, FLV, MOV, or MP4 video files from a
  series of static PNG images.

These programs are entirely separate from The W2 Animator, and are NOT
required by W2Anim for the program to function.  It is the responsibility
of the user of W2Anim to install these programs (or not), depending on
whether the user wants the functionality mentioned above.  Both Ghostscript
and FFmpeg are free software, but the user should examine the details of
their license agreements to ensure that they are properly used.


## Ghostscript

Ghostscript is a powerful and commonly used interpreter for the PostScript
language and for Portable Document Files (PDFs). Artifex Software maintains
and develops the Ghostscript software and has ported it to a number of
operating systems including Windows and Linux.  As of this writing,
the current version is 10.06.0, and that is the version I am using.
The source code as well as pre-compiled binaries are available at:

- [https://www.ghostscript.com/](https://www.ghostscript.com/)
- [https://www.ghostscript.com/releases/gsdnld.html](https://www.ghostscript.com/releases/gsdnld.html)

Ghostscript is available as open source software under the [GNU Affero
General Public License](https://www.gnu.org/licenses/agpl-3.0.html).

The important point is that Open Source Ghostscript is free to use.
None of the source code has been modified for use with W2Anim, none of
the source code has been incorporated into W2Anim, and Ghostscript is
not distributed with W2Anim.  It is up to the user to decide whether to
use Ghostscript in conjunction with W2Anim.  If the user wishes to export
screenshots or animations from W2Anim, then the user may find it useful
to install and use Ghostscript as a helper application to W2Anim.  See the
Help/Configure menu option in The W2 Animator to ensure that W2Anim knows
where Ghostscript is located on your computer.

In Windows, you can install Ghostscript by running the installation
executable program as Administrator.  I suggest that you install the
program under
```
C:\Program Files\gs\gsxx.xx.xx
```
where the xx stuff refers to the version number.  For example, my
installation location is
```
C:\Program Files\gs\gs10.06.0\
```


## FFmpeg

FFmpeg is a powerful set of tools and libraries for decoding,
encoding, translating, and reformatting almost every type of
audio and video file.  It is free to use and is covered under
the GNU General Public License (GPL) version 2 or later.  See
[https://ffmpeg.org/legal.html](https://ffmpeg.org/legal.html) for more
information.

FFmpeg may be used with W2Anim as a helper program to make AVI, FLV, MOV,
and MP4 video output files from a series of PNG images.  FFmpeg is not
needed in order to run or use W2Anim, and it is up to the user to decide
whether (or not) to download and install FFmpeg as a helper program.
None of the source code of FFmpeg has been incorporated into W2Anim,
and FFmpeg is not distributed with W2Anim.  If the user wishes to create
certain video output files, then the user may wish to download and install
FFmpeg or some other video software to accomplish that task.

FFmpeg tools include:
```
ffmpeg  -- a command line tool to convert multimedia files between various formats
ffplay  -- a simple media player
ffprobe -- a simple multimedia stream analyzer
```

More information and free downloads of the FFmpeg software can be found
online at the following URLs:

- [https://ffmpeg.org/](https://ffmpeg.org/)
- [https://ffmpeg.org/about.html](https://ffmpeg.org/about.html)
- [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html)

As of this writing, the current version of FFmpeg is 8.0.1, based on a build
from 20-Nov-2025.  Compiled packages of FFmpeg are available for Windows at:

- [https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
- [https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-full.7z](https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-full.7z)

The compiled package for Windows mentioned above does not come with
an installer.  To install FFmpeg on your Windows system, create the
following directory:
```
C:\Program Files\FFmpeg\
```
and then unzip the package so that the following folders exist:
```
C:\Program Files\FFmpeg\bin
C:\Program Files\FFmpeg\doc
C:\Program Files\FFmpeg\presets
```

Lastly, you may wish to put the C:\Program Files\FFmpeg\bin folder on the
system PATH so that the programs are more easily accessible, but this is
not strictly necessary if you use the folders as suggested above and/or
provide the appropriate path to the FFmpeg programs to The W2 Animator
program under the Help/Configure menu.


## Video Format Notes

W2Anim, when used with Ghostscript and FFmpeg, can create several types
of video output files.  Although the smoothest and possibly fastest way
to view W2Anim animations is probably within W2Anim itself, you may find
it useful to export video files to share with your colleagues or partners.
The following video formats are available for export from W2Anim.  You can
research their advantages and disadvantages yourself, but here is my take:

- **AVI** -- Audio Video Interleave format.  This is an older video format
  that is still in use and is compatible with a wide range of video players.
  Quality is high, but the file size will be larger than MOV or MP4 formats.

- **FLV** -- Flash Video format. This format was developed for use with the
  Adobe Flash player, and often was used for showing videos in web pages. It
  is provided just in case some older compatibility for web pages is needed.

- **GIF** -- Animated Graphics Interchange Format. Animated GIFs have enjoyed
  somewhat of a resurgence in popularity for small animations, but this
  format is not recommended unless you have no other options.  W2Anim can
  create animated GIFs without FFmpeg, but Ghostscript or a similar
  PostScript interpreter is still needed. This video format restricts the
  color palette to 256 colors, and compression of the final file is poor
  compared to other video formats.

- **MOV** -- QuickTime movie format. The MOV format was developed by
  Apple and is compatible with Windows and MacOS systems. It uses the MPEG-4
  encoding algorithms and results in smaller file sizes compared to AVI,
  FLV, and GIF formats.

- **MP4** -- MPEG-4 format. The latest MPEG-4 format was derived at one
  time from the QuickTime movie format. MP4 files are commonly used for
  modern videos, and file sizes are small compared to the AVI, FLV, and
  GIF formats.  File sizes for MP4 and MOV files created by FFmpeg through
  W2Anim will be the same.


## Video Codecs

Your computer probably already has most of the video codecs required
to encode, decode, compress, and decompress the data in video files.
If a video player on your system cannot play a particular video file,
it may or may not be due to not having the proper codecs installed.
Many video players rely on codecs that are compiled into their code, but
some rely on libraries installed with the operating system.  If you wish
to update the codecs on a Windows computer, you may wish to download and
install the codecs contained in the "K-Lite Codec Pack Standard" available
at [https://www.codecguide.com/download_k-lite_codec_pack_standard.htm](https://www.codecguide.com/download_k-lite_codec_pack_standard.htm).


## Video Players

Many video players are available, but not all of them can open and play
the video files that may be exported by W2Anim with or without FFmpeg as
a helper program.  Here is a limited list of some video players that may
be useful:

- **MPC-HC**:  The K-Lite Codec Pack includes a video player program
  called MPC-HC that can be used to view just about any video file
  and has some decent user controls.

- **VLC Media Player**:  The VLC Media Player also can be used to view
  just about any video file and comes with its own codecs compiled into
  the program.  This is a very useful video viewer, but I personally
  don't like the user controls as much as those in some other programs.

- **MPV**:  The MPV player works well, but personally I find the user
  controls of some other players to be more useful.

- **IrfanView**:  IrfanView is a powerful image editor program that
  also can play certain types of video files, depending on the codecs
  that are installed and known by that program. Give it a try to see
  if you like it, but recognize that it won't work in all instances,
  and the user controls are limited.

- **Windows Media Player**:  The Windows Media Player still exists,
  but is no longer under development and has been superceded with
  other tools in Windows 11.  Some types of video files will not play
  in this older viewer.

- **ffplay**:  The video player that comes with the FFmpeg package is
  simple, but portable, and should work with video files produced by
  FFmpeg. The user controls are minimal, and most options are invoked from
  a command line. Still, it may be a useful option in some situations.

- **Woldo's MCI Video File Player**:  Despite the fact that this is
  the oldest and most out-of-date video file player in this list, it can
  still be made to view the AVI files created by W2Anim in conjunction
  with FFmpeg.  I like the user controls and the fact that the video
  can be viewed one frame at a time at superspeed in both forward and
  reverse directions.  It's a useful program to have, depite its age and
  incompatibility with more modern video formats.  It may be hard to find
  a copy of this program online.
