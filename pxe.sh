#!/bin/bash
#@(#) pxe_setup	for Debian 12	                       	© Lech Taczkowski
#------------------------------------------------------------------------------
#< Description:    This script does initial configuration of the PXE installation
#                  environment. It sets up a tftp, nfs, http, ftp servers or all
#		   at once. Boot files are served from /srv/tftp.
#		   The directory with data can be specified or default.
#		   All data put in this directory can be server by the
#		   supported protocols. atftpd will start on demand.
#		   You will not see it's process nor services running in the
#		   background.
#		   You will still need to create menus and add files related
#		   to specific distributions.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

echo "

██████╗ ██╗  ██╗███████╗                                                                     
██╔══██╗╚██╗██╔╝██╔════╝                                                                     
██████╔╝ ╚███╔╝ █████╗                                                                       
██╔═══╝  ██╔██╗ ██╔══╝                                                                       
██║     ██╔╝ ██╗███████╗                                                                     
╚═╝     ╚═╝  ╚═╝╚══════╝                                                                     
                                                                                             
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                             
███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗                                             
██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗                                            
███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝                                            
╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗                                            
███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║                                            
╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝                                            
                                                                                             
SETUP SCRIPT
"

NOW=`date +'%d-%m-%Y_%H:%M'`
# Default directory for data
datadir="/srv/pxe"
# Default directory for boot files.
tftpdir="/srv/tftp"

bashrc_file="$HOME/.bashrc"

# Check if two directories are the same.
if [ "$datadir" == "$tftpdir" ]; then
	echo "[ERROR] Try a different \"datadir\". It can't be the same as the tftp directory."
	exit 1
    fi

# Function definitions

separator() {
	echo "======================================================================"
	}
tftpd_setup() {
    echo "[INFO] Setting up tftp in $tftpdir ..."
    mkdir -p $tftpdir; chmod 755 $tftpdir
    # Redirect to >/dev/null 2>&1 to hide output
    apt install atftpd -y
    echo 'OPTIONS="--port 69 --tftpd-timeout 300 --retry-timeout 5 --mcast-port 1758 --mcast-addr 239.239.239.0-255 --mcast-ttl 1 --maxthread 100 --verbose=5 /srv/tftp"' > /etc/default/atftpd
    mkdir -p $tftpdir/pxelinux.cfg
    touch $tftpdir/pxelinux.cfg/default
    
    if test -f $tftpdir/pxelinux.cfg/default; then
	cp -Prf $tftpdir/pxelinux.cfg/default $tftpdir/pxelinux.cfg/default.${NOW}.backup
    fi

    echo "# Menu example
timeout 900
ontimeout local1 

menu title ########## pxe.example.com ##########

label local1
menu label Uruchom z pierwszego lokalnego dysku
localboot 0
  text help
 Rozruch z pierwszego dysku twardego.
  endtext

label local2
menu label Uruchom z drugiego lokalnego dysku
localboot 1
  text help
 Rozruch z drugiego dysku twardego.
  endtext

label reboot
menu label Restart komputera
com32 reboot.c32

label poweroff
menu label Wylaczenie komputera
comboot poweroff.com

menu separator
" > $tftpdir/pxelinux.cfg/default

# Syslinux part
apt install syslinux pxelinux -y

cp -fR /usr/lib/syslinux/modules/bios/* $tftpdir/
cp -f /usr/lib/PXELINUX/pxelinux.0 $tftpdir/

systemctl enable atftpd
systemctl restart atftpd
separator
}

nfsd_setup() {
    echo "[INFO] Setting up NFS ..."
    mkdir -p $datadir; chmod 755 $datadir
    apt install nfs-kernel-server -y
    # Check and add line to /etc/exports if it's not already present
    if ! grep -q "^${datadir} " /etc/exports; then
        echo "$datadir *(ro,sync,no_root_squash)" >> /etc/exports
    fi
    systemctl restart nfs-kernel-server
    systemctl enable nfs-kernel-server    
    separator
}

httpd_setup() {
    echo "[INFO] Setting up HTTP ..."
    mkdir -p $datadir; chmod 755 $datadir
    apt install apache2 -y
    a2dissite 000-default.conf
    echo "<VirtualHost *:80>
    ServerName pxe.example.com
    DocumentRoot $datadir
    <Directory $datadir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/pxe.conf

    a2ensite pxe.conf
    systemctl restart apache2
    separator
}

ftpd_setup() {
    echo "[INFO] Setting up FTP ..."
    mkdir -p $datadir; chmod 755 $datadir
    apt install vsftpd -y
  	if test -f /etc/vsftpd.conf; then
	    cp -Prf /etc/vsftpd.conf /etc/vsftpd.conf.${NOW}.backup
    fi
    # Modify configuration file.
    config_file="/etc/vsftpd.conf"
    temp_file=$(mktemp)

    # Define the new configuration
    new_config=$(cat <<EOF
anonymous_enable=YES
local_enable=NO
anon_upload_enable=NO
anon_mkdir_write_enable=NO
write_enable=NO
anon_root=$datadir
no_anon_password=YES
hide_ids=YES
pasv_min_port=40000
pasv_max_port=50000
EOF
)
    # Copy existing configuration to temp file, excluding lines that match new configuration
    grep -v -E "^(anonymous_enable|local_enable|anon_upload_enable|anon_mkdir_write_enable|write_enable|anon_root|no_anon_password|hide_ids|pasv_min_port|pasv_max_port)=" $config_file > $temp_file

    # Append new configuration to temp file
    echo "$new_config" >> $temp_file

    # Replace original config file with updated temp file
    mv -f $temp_file $config_file
    
    systemctl restart vsftpd
    systemctl enable vsftpd
    separator
}

# Help function
show_help() {
    echo "Usage: $0 [--tftp] [--nfs] [--http] [--ftp] [--datadir <directory>] [--all]"
    echo "  --tftp       Run TFTP setup (default data directory for tftpd is: $tftpdir"
    echo "  --nfs        Run NFS setup"
    echo "  --http       Run HTTP setup"
    echo "  --ftp        Run FTP setup"
    echo "  --all        Setup all of the above"
    echo "  --datadir    Specify data directory (default: /srv/files)"
    exit
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --tftp) tftp=true ;;
        --nfs) nfs=true ;;
        --http) http=true ;;
        --ftp) ftp=true ;;
        --datadir) datadir="$2"; shift ;;
        --all) all=true ;;
        *) show_help; exit 1 ;;
    esac
    shift
done

# Execute functions based on arguments
if [[ "$all" == true ]]; then
    tftpd_setup
    nfsd_setup
    httpd_setup
    ftpd_setup
else
    [[ "$tftp" == true ]] && tftpd_setup
    [[ "$nfs" == true ]] && nfsd_setup
    [[ "$http" == true ]] && httpd_setup
    [[ "$ftp" == true ]] && ftpd_setup
fi

# If no arguments were provided, show help
if [[ -z "$tftp" && -z "$nfs" && -z "$http" && -z "$ftp" && -z "$all" ]]; then
    show_help
fi

# Aliases

# Check and add aliases to .bashrc if they are not already present
if ! grep -q "alias cddatadir=" "$bashrc_file"; then
  echo "alias cddatadir=\"cd ${datadir}\"" >> "$bashrc_file"
fi

if ! grep -q "alias cdtftpdir=" "$bashrc_file"; then
  echo "alias cdtftpdir=\"cd ${tftpdir}\"" >> "$bashrc_file"
fi

if ! grep -q "alias cdmenu=" "$bashrc_file"; then
  echo "alias cdmenu=\"cd ${tftpdir}/pxelinux.cfg\"" >> "$bashrc_file"
fi

source ${bashrc_file}
