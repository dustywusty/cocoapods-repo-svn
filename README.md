[![Gem Version](https://badge.fury.io/rb/cocoapods-repo-svn.svg)](http://badge.fury.io/rb/cocoapods-repo-svn)

# Cocoapods::RepoSvn

Adds subversion support to manage spec-repositories

## Brief

Our team had been using a in house fork of Cocoapods with svn, bzr, and hg spec-repo support. Since #1747 has been closed, I'm porting that code to plugins

## Installation

    $ gem install cocoapods-repo-svn 

## Usage

Add

    $ pod repo-svn add my-svn-repo http://svn-repo-url
  
Update

    $ pod repo-svn update my-svn-repo 

Remove

    $ pod repo-svn remove my-svn-repo 

    
## Contributing
    
..

## Building

    $ rake build
    
## Installing

    $ rake install

    
## Thoughts

Repo->Remove and Repo->Lint are generic enough to be lifted out of git specific command/repo
