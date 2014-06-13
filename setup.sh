#!/bin/sh
## Durendals Arch Setup Script!
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo "Welcome to Durendals Arch Setup Script! Hopefully this will make configuring arch a little simpler for you"
echo ""
if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    exit 1
fi

set_network()
{
	echo "Beginning Network Configuration"
	echo ""
	read -p "Configure Wired Ethernet Adapter? [Y/n]: " eth_con
	case $eth_con in
		[Nn]* ) echo "Skipping Network Configuration";;
		[Yy]* ) eth0=`ip addr | grep enp | cut -d ' ' -f 2 | sed 's/://g'` # Determine the wired network interface
				echo "Attempting to lease ip to $eth0"
				dhcpcd $eth0
				# Enable auto connect on boot
				systemctl enable network@$eth0
				# Enable auto connect/disconnect based when a network cable is detected 
				systemctl enable netctl-ifplugd@$eth0;;

			* ) echo "Invalid option entered."
				exit 1;;
	esac

	read -p "Configure Wireless Adapter? [y/N]" wifi_con
	case $wifi_con in
		[Nn]* ) echo "Skipping Wifi Configuration";;
		[Yy]* ) wlp0=`ip addr | grep wlp | cut -d ' ' -f 2 | sed 's/://g'` # Determine the wireless network interface
				# Have netctl automatically connect to known host on startup
				read -p "Please enter the SSID: " ssid
				read -p "Please enter the encryption type: " sec
				read -p "Please enter the passphrase: " pass
				echo "Description='Auto-Generated config by Durendal'" > /etc/netctl/$ssid
				echo "Interface=$wlp0" >> /etc/netctl/$ssid
				echo "Connection=wireless" >> /etc/netctl/$ssid
				echo "Security=$sec" >> /etc/netctl/$ssid
				echo "ESSID=$ssid" >> /etc/netctl/$ssid
				echo "IP=dhcp" >> /etc/netctl/$ssid
				echo "Key=\"$pass\"" >> /etc/netctl/$ssid

				pacman -S wpa_actiond
				netctl enable $ssid;;
			* ) echo "Invalid option entered."
				exit 1;;
	esac



	echo ""
	echo "Network Configuration Complete"
	echo ""
	echo ""
## /End of Network Configuration
}

set_user()
{
	## Add New User
	read -p "Would you like to add a new user to the system?[Y/n]: " user
	case $user in
		[Yy]* ) 
				read -p "Please enter username: " name
				useradd -m $name
				passwd $name
				echo "New user: $name added!";;
		[Nn]* ) echo "Skipping user creation step.";;
			* ) echo "Invalid option entered."
				exit 1;;
	esac

	read -p "Add $name to sudoers file?[Y/n]: " sudoers
	case $sudoers in
		[Yy]* ) 
				echo "$name ALL=(ALL:ALL) ALL" >> /etc/sudoers
				echo "Added $name to /etc/sudoers";;
		[Nn]* ) echo "Skipping add $name to sudoers";;
			* ) echo "Invalid option entered";;
	esac
	## /End Add New User
}

set_video()
{
	## Choose the Video driver to install on the host system
	echo "Beginning Video Driver Installation:"
	echo ""

	echo "Install Video Driver:"
	echo -e "\t1) Intel"
	echo -e "\t2) NVIDIA"
	echo -e "\t3) ATI"
	echo -e "\t4) None"
	echo -e "\t5) Custom"
	echo ""
	echo ""
	read -p "Enter Driver Selection(number): " v_driver
	echo ""
	echo ""
	case $v_driver in
		[1]* ) c_driver="xf86-video-intel";;
		[2]* ) c_driver="xf86-video-nouveau";;
		[3]* ) c_driver="xf86-video-ati";;
		[4]* ) c_driver=0;;
		[5]* ) echo "Please enter the name of the driver as it appears in the repos: "
			   read c_driver;;
		* ) 	echo "Invalid option entered."
				exit 1;;
	esac

	case $c_driver in
		[0]* )  echo "Skipping video driver Install(Headless Configuration)"
				echo "Skipping Xorg Install(Headless Configuration)";;

		   * )  echo "Installing: $c_driver"
				pacman -S $c_driver
				echo "Installing Xorg-server Xorg-server-utils Xorg-xinit and Xorg-apps"
				pacman -S xorg-server xorg-server-utils xorg-xinit Xorg-apps
				echo ""
				echo "Install MATE DE?[Y/n]"
				read install

				case $install in
					[Nn]* ) echo "Skipping Mate DE Install";;
					[Yy]* ) echo "Installing Mate DE..."
							pacman -S mate mate-extras
							echo ""
							echo "Install mate-netbook?[Y/n]"
							read netbook
							case $netbook in
								[Nn]* ) echo "Skipping mate-netbook Install...";;
								[Yy]* ) echo "Installing mate-netbook"
										pacman -S mate-netbook;;
									* ) echo "Invalid Option Entered..."
						    			exit 1;;
						    esac
						    echo ""
						    echo "Install Additional Mate Packages?[Y/n]"
						    read add_mate
						    case $add_mate in
						    	[Nn]* ) echo "Skipping Additional Mate Packages...";;
								[Yy]* ) echo "Installing Additional Mate Packages..."
										pacman -S mate-nettool variety mate-disk-utility;;
									* ) echo "Invalid Option Entered..."
						    			exit 1;;

						    esac;; 
					    * ) echo "Invalid Option Entered..."
						    exit 1;;
				esac;;
	esac

	echo ""
	echo "Video Setup Complete."


	## /End of Video Setup
}

tools()
{
	echo "Installing useful tools:"
	echo -e "\tgedit"
	echo -e "\tgit"
	echo -e "\tyaourt"
	echo -e "\tpidgin"
	echo -e "\tpidgin-otr"
	echo -e "\tfirefox"
	echo -e "\tssh" 
	echo -e "\twget"

	pacman -S gedit git pidgin pidgin-otr firefox openssh wget libcups

	echo "Beginning Installation of package-query"
	wget -O package-query.tar.gz https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
	tar -xzvf package-query.tar.gz -C ./package-query
	cd package-query
	makepkg -s
	pacman -U `ls | grep tar.xz`
	cd ..
	echo ""
	echo ""
	echo "Beginning Installation of yaourt"
	wget -O yaourt.tar.gz https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
	tar -xzvf yaourt.tar.gz -C ./yaourt
	cd yaourt
	makepkg -s
	pacman -U `ls | grep tar.xz`
	cd ..
	echo "Finished Installing yaourt"
	echo ""
	echo ""
	echo "Beginning installation of Sublime Text"
	mkdir ~/Program\ Files
	cd ~/Program\ Files
	wget -O sublime_text.tar.bz2 http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2.tar.bz2
	tar -xvjf sublime_text.tar.bz2
	cd ..
	echo "Finished Installing Sublime Text."
	echo ""
	echo ""
	read -p "Is there a CUPS server you would like to add?[Y/n]: " addcups
	case $addcups in
		[Yy]* ) 
				read -p "Enter Print Server Address: " pserv
				sed -i 's/\/var\/run\/cups\/cups.sock/$pserv/g' /etc/cups/client.conf
				echo "CUPS client file has been updated.";;

		[Nn]* ) echo "Skipping CUPS configuration";;
			* ) echo "Invalid option entered";;
	esac
}

server()
{
	echo "Installing Lamp Server:"
	pacman -S php apache mariadb php-apache
	echo "Finished installing LAMP Server"
	echo "Please consult https://wiki.archlinux.org/index.php/LAMP for information on configuration."
	echo ""
	echo ""
	echo "Installing CUPS server"
	pacman -S libcups cups ghostscript gsfonts gutenprint foomatic-db foomatic-db-engine foomatic-db-nonfree avahi nss-mdns
	avahi-autoipd -D $eth0
	echo "Please see https://wiki.archlinux.org/index.php/avahi for avahi configuration"
	echo "Please see https://wiki.archlinux.org/index.php/CUPS for cups configuration"
	echo ""
	echo ""
	echo "Downloading Universal Media Server"
	wget -O ums.tar.gz http://sourceforge.net/projects/unimediaserver/files/Official%20Releases/Linux/UMS-3.6.0.tgz/download
	tar -xzvf ums.tar.gz -C /srv
	echo "Please see http://www.universalmediaserver.com/about/ for more information"
	echo ""
	echo ""
	pacman -S deluge
	systemctl enable deluged
	systemctl start deluged
	systemctl enable deluge-web
	systemctl start deluge-web
	echo "Deluge should now be available at your host on port 8112"
	echo "Please see https://wiki.archlinux.org/index.php/deluge for more information"

	echo "Configuring ssh server"
	read -p "What port do you want to run on?: " sshport

	re='^[0-9]+$'
	if ! [[ $sshport =~ $re ]] ; then
   		echo "error: Not a valid port" >&2; exit 1
	fi

	sed -i 's/#Port 22/Port $sshport/g' /etc/ssh/sshd_config
	systemctl enable sshd
	systemctl start sshd

}

read -p "Setup Network?[Y/n]" netz
case $netz in
	[Yy]* ) set_network;;
	[Nn]* ) echo "Skipping network setup..." ;;
		* ) echo "Invalid option submitted"
			exit 1;;
esac

read -p "Setup new user?[Y/n]" uz
case $uz in
	[Yy]* ) set_user;;
	[Nn]* ) echo "Skipping new user setup..." ;;
		* ) echo "Invalid option submitted"
			exit 1;;
esac

read -p "Setup Video?[Y/n]" vid
case $vid in
	[Yy]* ) set_video;;
	[Nn]* ) echo "Skipping video setup..." ;;
		* ) echo "Invalid option submitted"
			exit 1;;
esac

read -p "Install Tools?[Y/n]" toolz
case $toolz in
	[Yy]* ) tools;;
	[Nn]* ) echo "Skipping tools setup..." 
			echo "Skipping server setup..." # server() requires wget, so without the tools install it is not run.
			exit 1;;
		* ) echo "Invalid option submitted"
			exit 1;;
esac

read -p "Configure Host as Server?[y/N]" serv
case $serv in
	[Yy]* ) server;;
	[Nn]* ) echo "Skipping Server setup..." ;;
		* ) echo "Invalid option submitted"
			exit 1;;
esac
