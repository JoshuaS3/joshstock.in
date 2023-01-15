---
type: none
identifier: recover-linux-shell
title: Recovering a Linux desktop with a misconfigured shell
description: How to fix a custom shell when your terminal can't open.
datestring: 2022-11-10
banner_image: /static/images/esp32.jpg
links:
   chsh: https://man7.org/linux/man-pages/man1/chsh.1.html
   xonsh: https://xon.sh/
   Virtual consoles: https://www.wikiwand.com/en/Virtual_console
   /etc/passwd: https://man7.org/linux/man-pages/man5/passwd.5.html
---

Suppose you’ve used the `chsh` command to change your login shell in the past
and something has gone wrong to the point that your custom shell executable is
nonexistent or no longer functions properly. Opening a new terminal results in
the window closing immediately following a fatal error, or you can’t log in to
your desktop entirely. For me, this happened with `xonsh` (a great amalgam of
Python and Bash) when upgrading between Ubuntu versions, as the installed
Python library fell out of the system path. There are a few methods, however,
to regain access to a functioning shell.

# Gaining access to a functioning shell

## Method 1(a): Application launching

This method assumes the following:

- You are still signed in to your semi-functioning desktop environment (DE)
- You have a functioning terminal emulator and shell installed on your system
- Your DE offers application launching

This one is pretty self-explanatory. Terminal emulators can be fed command-line
arguments to skip shell loading entirely and perform direct file execution. You
can use this option to load a shell other than your user’s default shell, as
shells are just executable files. Here are some example commands to load Bash
with different terminals, bypassing your login shell:

```bash
xterm -e /usr/bin/env bash
xfce4-terminal -e /usr/bin/env bash
gnome-terminal -- /usr/bin/env bash
```

If your DE offers application launching, you can execute the appropriate
command for your terminal emulator and (functional) shell of choice. The
shortcut for application launching on Gnome and XFCE is `<Alt><F2>`. On KDE,
it’s `<Alt><F1>`, and on i3, which uses dmenu, it’s `<Ctrl>D`. For other
desktop environments with application launchers, check which you should use in
the related documentation.

## Method 1(b): GUI-based file execution

This is an alternative method to 1(a), assuming:

- You are still signed in to your semi-functioning desktop environment (DE)
- Your DE *does not* have application launching, or it doesn’t work for some
reason
- You have a functioning terminal emulator and shell installed on your system
- Your GUI file browser offers direct file execution without terminal

Essentially, you create a file like the following, using the appropriate
terminal emulator and shell:

```bash
#!/usr/bin/env bash
gnome-terminal -- /bin/bash
```

Using your file browser, give this file permission for user execution and run
it.

## Method 2: Use another user with a functioning login shell

This method assumes:

- There is a separate user on your system that can be logged into via password
that uses a functioning login shell
- The user is a member of the sudo group

Open a virtual console (usually with `<CTRL><ALT><F1..F9>`) and log in as the
separate user. Then, you can take the necessary actions to fix your broken
login shell or other configuration. (On my systems I create a sudoer named
`bash-user` whose sole purpose is to be password-login-able with Bash as its
login shell.)

If you don’t have this option, then…

## Method 3: Externally mount the filesystem and forcibly change the default login shell

This is the most involved and complicated method, meant to be used as a last
resort if you don’t feel like reimaging your system (or living without a
terminal). You will need to find a way to externally mount the filesystem from
another functioning operating system and change the `/etc/passwd` file
directly.

For desktops without any other operating systems installed, my go-to method
looks roughly like this:

1. Create a live USB bootable Linux distribution on a flash drive
   (Linux-on-a-stick)
2. UEFI boot into this Linux-on-a-stick
3. Force mount the hard drive your Linux system is on, with sufficient
   read-write permissions *(Look for external help on this, so as to not break
   your filesystem or mess up permissions)*

The full details of this method are a bit out of the scope of this article, so
I’ll let you figure them out with the help of Google and StackOverflow. Having
a bootable Linux-on-a-stick is also useful for other reasons, so if you don’t
have one, I do recommend setting one up and using the steps outlined above.

Once your filesystem is mounted and you have sufficient read/write permissions,
you can do one of the following:

- Directly change `/etc/passwd` to reflect a working login shell for your user
- Through the external operating system, take the necessary actions to fix your
  broken login shell (not recommended)

After completing this, you should be able to log into your system as normal.

# Fixing your custom shell

This will vary widely depending on your setup and the shell you’re trying to
fix, so unfortunately I can’t cover that extensively here. In my case, for
fixing `xonsh`, I just had to reinstall it via Python’s package manager with
this command:

```bash
$ sudo python3 -m pip install 'xonsh[full]'
```

Your process for fixing your broken shell will likely be a similar process of
reinstallation or reconfiguration via `chsh`.
