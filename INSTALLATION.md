# INSTALLATION of Perl and Tcl 

The W2 Animator is written in Perl and uses the Tcl/Tk toolkit for its
user interface.  To run the program, both Perl and Tcl must be installed,
along with several required modules of those interpreters.  Tcl is needed
because the Tk module in Perl is not up to date, whereas the Tcl/Tk module
is up to date.  The W2 Animator requires version 8.6 of Tk to build and use
all of the features of its user interface, and the Tcl/Tk module utilizes
version 8.6 or later of Tk.

These instructions describe how to install the Strawberry Perl and ActiveTcl
distributions of Perl and Tcl, respectively, on a 64-bit Windows system.
If you wish to install different distributions of these languages, feel free,
but the instructions here are specific to Strawberry Perl and ActiveTcl.
The W2 Animator should work on multiple operating systems, but you may
need different source distributions of Perl and Tcl to make it work on
each operating system.


## Step 1.  Install Strawberry Perl

Strawberry Perl is a free distribution of Perl for Windows that
is designed to be as close as possible to the Perl environments
on unix systems.  Strawberry Perl is free and available at
[https://strawberryperl.com/](https://strawberryperl.com/).  Download the
installer for your system and install it as you would normally install
any Windows program.  I installed version 5.32.1.1 (64-bit) to my system
at C:\Perl\Strawberry\.


## Step 2.  Install ActiveTcl

ActiveState provides packages for several useful languages.
I signed up for a free account at ActiveState, which you can find at
[https://www.activestate.com/products/tcl/](https://www.activestate.com/products/tcl/).
I downloaded the standard Tcl package for Windows, which at the time was
version 8.6.12.0000 (64-bit).  Install it as you would any Windows program.
I installed my package to C:\Tcl\ActiveTcl\.

Depending on whether ActiveState has modified their standard Tcl distribution
package, you may need to make a few edits.  I had to modify one file in
the Tcl package after installation.  In the file:
```
C:\Tcl\ActiveTcl\lib\tclConfig.sh
```
I found six lines that the installer did not properly complete in that file.
Here are the 6 lines, where I commented out the first line in the pair,
copied it to the second line and edited the second line to have the correct
path and syntax:

```
#TCL_PREFIX='C:\TEMP\ActiveState----------------------------------------please-run-the-install-script----------------------------------------'
TCL_PREFIX='C:\Tcl\ActiveTcl'

#TCL_EXEC_PREFIX='C:\TEMP\ActiveState----------------------------------------please-run-the-install-script----------------------------------------\bin'
TCL_EXEC_PREFIX='C:\Tcl\ActiveTcl\bin'

#TCL_LIB_SPEC='C:\TEMP\ActiveState----------------------------------------please-run-the-install-script----------------------------------------\lib\tcl86t.lib'
TCL_LIB_SPEC='-LC:\Tcl\ActiveTcl\lib\tcl86t.lib'

#TCL_INCLUDE_SPEC='-IC:\TEMP\ActiveState----------------------------------------please-run-the-install-script----------------------------------------\include'
TCL_INCLUDE_SPEC='-IC:\Tcl\ActiveTcl\include'

#TCL_STUB_LIB_SPEC='-LC:\TEMP\ActiveState----------------------------------------please-run-the-install-script----------------------------------------\lib tclstub86.lib'
TCL_STUB_LIB_SPEC='-LC:\Tcl\ActiveTcl\lib tclstub86.lib'

#TCL_STUB_LIB_PATH='C:\TEMP\ActiveState----------------------------------------please-run-the-install-script----------------------------------------\lib\tclstub86.lib'
TCL_STUB_LIB_PATH='C:\Tcl\ActiveTcl\lib\tclstub86.lib'
```

With these modifications to the tclConfig.sh file, Strawberry Perl will
be able to download and properly compile the Perl Tkx module, which is a
simple interface to the Tcl/Tk package.  Without these modifications, the
Tkx interface in Perl to Tcl/Tk will not be available and The W2 Animator
program will not run properly.


## Step 3.  Modify the System PATH (optional)

I found it useful to modify the Windows system PATH.  The installer
for ActiveTcl unnecessarily puts its folder at the top of the PATH list,
whereas Strawberry Perl puts its entries at the bottom of the system PATH.
To modify your Windows system PATH, click the Start menu and select Settings.
Then type "system path" into the search bar.  On Windows, you need to be
Administrator to modify the system PATH.  You may or may not need to get
your system administrator to assist you with some of these installations.

I moved the three entries for Strawberry Perl up to the top, before the
Tcl path, as follows:
```
C:\Perl\Strawberry\c\bin
C:\Perl\Strawberry\perl\site\bin
C:\Perl\Strawberry\perl\bin
C:\Tcl\ActiveTcl\bin
```


## Step 4.  Install Required Perl Modules

The W2 Animator requires several additional Perl modules to be installed.
This is a common task and is simple to carry out.

Start by opening Strawberry Perl's text interface.  Check the Start menu
for a new item-- it is probably labelled "Perl (command line)."  I added
a shortcut to my tray for future use.

New modules can be installed in Strawberry Perl, and indeed in most Perl
distributions, by using the "cpanm" command.  It's really simple, but pay
attention to the messages it prints to the screen.  If you have problems, you
should be able to find a "build.log" file in C:\Users\your_user_name\\.cpanm\\
that will be more verbose.  You will also find more build logs under
C:\Users\your_user_name\\.cpanm\work\\.

Running as Administrator (I don't know if this is necessary), I started
by installing the Perl Tkx module with:
```
cpanm Tkx
```
This module is small and quick to install, but it requires the Tcl module
as a dependency, and so will install the Tcl module as well.  The Tcl/Tk
module is used for creating user interfaces.  As a result, you will see
many different windows popping up as various tests are generated and run.
Do not be alarmed, as this is normal.

Other Perl modules that you will need, and their installation commands:
```
cpanm Tkx::ROText
cpanm Tkx::Scrolled
cpanm Proc::Background
cpanm File::Find::Object
cpanm Win32::GUI
```

The rest of the modules required by The W2 Animator should already be
part of the standard distribution of Strawberry Perl.  For example, the
Math::Trig and Imager modules are already installed.

Finally, I found one error in my older Strawberry Perl Tcl module; you
probably don't have this problem, but it doesn't hurt to check.  You may
need to edit the file at:
```
C:\Perl\Strawberry\perl\site\lib\Tcl.pm
```
In that file, find the line that looks like:
```
      print "TCL::TRACE_DELETECOMMAND: $interp -> ( $tclname )\n" if TRACE_DELETECOMMAND();
```
This line may or may not be missing a "Tcl::" in front of the final
TRACE_DELETECOMMAND.  So, the fixed line should look like:
```
      print "TCL::TRACE_DELETECOMMAND: $interp -> ( $tclname )\n" if Tcl::TRACE_DELETECOMMAND();
```
Doing this little edit may be tricky, as the default file permissions for the
Tcl.pm file don't include write permissions, even for the owner.  I worked
around it by changing the file's user write permission while logged in as
Administrator in my Cygwin environment and editing the file with vi there.
Another user reported that you can open the file in Notepad++, right-click
on the file-name tab, and choose the option to clear the ReadOnly flag.
You may find another solution.

That's all.  You should now have a functioning Strawberry Perl environment
with ActiveTcl available to assist.
