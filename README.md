Linux PXE Setup Script

Tested on Debian 12.

This script does initial configuration of the PXE installation
environment. It sets up a tftp, nfs, http, ftp servers or all
at once. Boot files are served from /srv/tftp.
The directory with data can be specified or default.
All data put in this directory can be server by the
supported protocols. atftpd will start on demand.
You will not see it's process nor services running in the
background.
You will still need to create menus and add files related
to specific distributions.
Internet access is expected.

Usage:

Usage: $0 [--tftp] [--nfs] [--http] [--ftp] [--datadir <directory>] [--all]
  --tftp       Run TFTP setup
  --nfs        Run NFS setup
  --http       Run HTTP setup
  --ftp        Run FTP setup
  --all        Setup all of the above
  --datadir    Specify data directory

You can setup the PXE server with tftp and other chosen protocols.
You must use --tftp parameter, then pick any other available protocols, like: nfs, ftp, http or just use --all to install and setup all of them.
For tftp the path for the boot files is hardcoded: /srv/tftp, because it will never need much free space.
All other files will be served from the same location specified by --datadir.

Examples:

-setup up tftp and ftp with default paths:

pxe.sh --tftp --ftp

-setup everything in one go:

pxe.sh --all

-setup tftp, http and ftp with a specific directory for data:

pxe.sh --tftp --http --ftp --datadir /data
