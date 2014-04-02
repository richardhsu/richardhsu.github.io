---
layout: post
comments: true
title: "RVM on OS X Mavericks"
date: 2014-04-01 17:03:00
---

Ruby Version Manager (RVM) and OS X Mavericks can be painful. Though if you use
Ruby then you should use RVM so hopefully this guide can help. There's a lot of
issues with getting it to work. I am a course assistant for the Web Applications
course at Stanford University and we have students install RVM, Ruby, and Rails
and there have been so many issues that I thought I'd make a post. I can't
guarantee that this will work but I've tested it many times for OS X Mavericks
that I believe it should work!

<!--more-->

Main test setup has been a virtual machine with a fresh install of Mac OS X
Mavericks thus if you have certain developer tools installed then this may have
some conflicts, but if you leave a comment with errors, I could possibly help!

In general, these instructions work for Mavericks but should theoretically work
for past versions as well now.

## Command Line Tools in Terminal

Open up the terminal and run the following command (a pop-up will appear
which you should continue and install):

```bash
sudo xcode-select --install
```

This will install the command line tools necessary to build and configure the
RVM installation.

## Homebrew

You should next install [homebrew][homebrew]. As of today, the RVM installation
utilizes homebrew to install dependencies and we will install it first before
RVM. The RVM installation will sometimes fail without homebrew first
installed. You should run the following command (or view the homebrew website
for the most up to date installation command):

```bash
ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
```

Next, after finishing, you should run `brew doctor` to verify everything is
good with your system, if there are any errors, attempt to remedy the situations
which homebrew will try to help with advice.

## RVM

Install RVM using the following command (you can also install it by following
the instructions on the website at [rvm.io][rvm]):

```bash
\curl -sSL https://get.rvm.io | bash -s stable --auto-dotfiles
```

This step can take a few minutes as it needs to install dependencies as well
using homebrew. I've seen it range between 5-30 minutes but luckily it shows a
little status information.

You may also need to provide a password at some point depending on your system
configuration as the installation may need privileges to create or modify
certain files or folders.

Finally, you'll want to completely quit the terminal and then reopen it so that
the settings take affect and you can now use RVM.

## Install Ruby

Now you're ready to install the Ruby version you'd like! For example if you want
version 2.1.1 then we can do the following in the terminal:

```bash
rvm install 2.1.1 --with-gcc=gcc
```

You should have GCC default installed on Mavericks so this should work and avoid
trying to install GCC 4.6 through homebrew. Then you can set the Ruby version to
the default one by doing the following command in the terminal:

```bash
rvm use 2.1.1 --default
```

Now you can type `ruby -v` to see the version which should show 2.1.1. And now
you have RVM installed on your system and you should be able to install
different versions of Ruby and use them!

## Notice

If you don't have Mavericks, you may still be able to follow these steps but
you might need to install the command line tools by downloading the `dmg` file
from the [Developer Website][apple] which requires an Apple ID to view (don't
worry, you don't need a Developer account). Download the latest command line
tools for your OS X version. Once you've downloaded it, open the `dmg` file and
install the package. Then continue from the top.

At some point you may also need to specify the version of `gcc` to run such as:

```bash
rvm install 2.1.1 --with-gcc=gcc
```

Some other options you may need are `clang` or `gcc46`. Good luck!

[apple]: https://developer.apple.com/downloads/index.action?name=command%20line%20tools
[homebrew]: http://brew.sh/
[rvm]: http://rvm.io/rvm/install
