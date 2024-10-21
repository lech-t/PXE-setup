# Linux PXE Setup Script

**Tested on Debian 12.**

This script does initial configuration of the PXE installation environment. It sets up a TFTP, NFS, HTTP, FTP servers, or all at once. Boot files are served from `/srv/tftp`. The directory with data can be specified or default. All data put in this directory can be served by the supported protocols. `atftpd` will start on demand. You will not see its process nor services running in the background. You will still need to create menus and add files related to specific distributions. Internet access is expected.

## Usage

Usage: $0 [–tftp] [–nfs] [–http] [–ftp] [–datadir <directory>] [–all]

–tftp Run TFTP setup –nfs Run NFS setup –http Run HTTP setup –ftp Run FTP setup –all Setup all of the above –datadir Specify data directory


You can set up the PXE server with TFTP and other chosen protocols. You must use the `--tftp` parameter, then pick any other available protocols, like NFS, FTP, HTTP, or just use `--all` to install and set up all of them. For TFTP, the path for the boot files is hardcoded: `/srv/tftp`, because it will never need much free space. All other files will be served from the same location specified by `--datadir`.

## Examples

- Set up TFTP and FTP with default paths:

    pxe.sh --tftp --ftp


- Set up everything in one go:

    pxe.sh --all


- Set up TFTP, HTTP, and FTP with a specific directory for data:

    pxe.sh --tftp --http --ftp --datadir /data

