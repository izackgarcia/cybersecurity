#!/bin/bash
mkdir /home/kali/Desktop/project1

log_file="/home/kali/Desktop/project1/p1.log"
echo '                       *** script starting ***'
echo "--- $(date) .............script starting... " >> /home/kali/Desktop/project1/p1.log
echo '*-- log file are located in Desktop/project1/'

#cheking if required apps are installed and installing them
function app_check() {
    local app=$1
    if command -v $app > /dev/null; then
        echo "--- $(date)........ $app is already installed ." >>  /home/kali/Desktop/project1/p1.log
        echo "--- $app is already installed."
    else
        echo "--- $(date)........ $app is not installed, installing..." >> /home/kali/Desktop/project1/p1.log
        echo "---  $app is not installed, installing..."
    fi
}


app_check ssh
out=$(app_check ssh)
if [ "$out" == "--- ssh is not installed, installing..." ];
then sudo apt-get install -y openssh-server
echo "---$(date)........... ssh installed." >> /home/kali/Desktop/project1/p1.log
echo "--- ssh installed."
fi

app_check whois
out=$(app_check whois)
if [ "$out" == "whois is not installed, installing..." ];
then sudo apt-get install -y whois
echo "--- whois installed." 
echo "---$(date)...........  whois installed." >> /home/kali/Desktop/project1/p1.log
fi

app_check netstat
out=$(app_check netstat)
if [ "$out" == "--- netstat is not installed, installing..." ];
then sudo apt-get install -y net-tools
echo "---$(date)........... netstat installed." >> /home/kali/Desktop/project1/p1.log
echo "--- netstat installed."
fi

app_check curl
out=$(app_check curl)
if [ "$out" == "--- curl is not installed, installing..." ];
then sudo apt-get install -y curl
echo "---$(date)........... curl installed." >> /home/kali/Desktop/project1/p1.log
echo "--- curl installed."
fi

app_check geoiplookup
out=$(app_check geoiplookup)
if [ "$out" == "--- geoiplookup is not installed, installing..." ];
then sudo apt-get install -y geoip-bin
echo "---$(date)........... geoiplookup installed." >> /home/kali/Desktop/project1/p1.log
echo "--- geoiplookup installed."
fi

app_check sshpass
out=$(app_check sshpass)
if [ "$out" == "--- sshpass is not installed, installing..." ];
then sudo apt-get install -y sshpass
echo "---$(date)........... sshpass installed." >> /home/kali/Desktop/project1/p1.log
echo "--- sshpass installed."
fi

app_check tor
out=$(app_check sshpass)
if [ "$out" == "--- tor is not installed, installing..." ];
then sudo apt-get install -y sshpass
echo "---$(date)........... tor installed." >> /home/kali/Desktop/project1/p1.log
echo "--- tor installed."
fi

# nipe installation for anonymity
nipe="/home/kali/Desktop/project1/nipe"
if [ -d "$nipe" ]; 
then
   echo "--- nipe exists on your system."	
else 
	cd /home/kali/Desktop/project1
	git clone https://github.com/htrgouvea/nipe
	cd nipe
	sudo cpan install Try::Tiny Config::Simple JSON
	sudo perl nipe.pl install
    echo "--- nipe successfully installed on your system!" 2>&1 | tee -a /home/kali/Desktop/project1/p1.log
fi

# anonymity process
myip=$(curl -s ifconfig.me)
country=$(geoiplookup "$myip"|awk -F ', ' '{print $2}' )

function ba ()
{
read -p "--- would you like to become anonymous? y\n:  " an
if [ $an == "y" ];
then 
echo "--- user wants to become anonymous" 2>&1 | tee -a /home/kali/Desktop/project1/p1.log
cd nipe
sudo perl nipe.pl restart
sleep 0.5
sudo perl nipe.pl restart
myip=$(curl -s ifconfig.io)
country=$(geoiplookup "$myip"|awk '{print $(NF-1), $NF}' )
echo "--- $(date)......... You are anonymous. your spoofed country is:  $country. " >> /home/kali/Desktop/project1/p1.log
echo "---  You are anonymous. your spoofed country is:  $country. "
else 
echo "--- $(date).........  user doesn't wish to become anonymous " >> /home/kali/Desktop/project1/p1.log
echo "--- ok, you are not anonymous. "
read -p "--- would you like to exit? y/n. " aa
   if [ $aa == "y" ];
   then 
   exit
   fi
fi
}

if [ "$country" == "Israel" ]
then
	echo "--- anonymity check..."
	sleep 1.5
    echo "--- $(date).......... You are not anonymous!" >> /home/kali/Desktop/project1/p1.log
    echo "---  You are not anonymous!" 
    ba
else
	myip=$(curl -s ifconfig.io)
	country=$(geoiplookup "$myip"|awk '{print $(NF-1), $NF}' )
	echo "--- you are anonymous! your spoofed country is: $country "
	
fi

#Allowing the user to specify the IP Address

echo "connection to remote server" 2>&1 | tee -a /home/kali/Desktop/project1/p1.log
read -p "specify the IP Address: " id
read -p "specify user name:" user 
read -p "specify password:" pw
echo "$(date) .........IP Address: $id . user name: $user . specify password: $pw " >> /home/kali/Desktop/project1/p1.log
 
# Connecting and Executing Commands on the Remote Server via SSH

function da ()
{
echo '--- connecting to remote server'
sshpass -p $pw ssh -o StrictHostKeyChecking=no $user@$id "sudo -S apt install curl whois nmap geoip-bin > /dev/null ; ei=\$(curl -s ifconfig.me); echo 'IP:' ; curl -s ifconfig.me ; echo '   ' ; echo 'Country:' ; geoiplookup \$ei; echo 'Uptime:'; uptime  " 2>&1 | tee -a /home/kali/Desktop/project1/p1.log
echo $(date) >> /home/kali/Desktop/project1/p1.3.log
sshpass -p $pw ssh -o StrictHostKeyChecking=no $user@$id "echo 'whois:'; whois $id ; echo 'open ports:'; nmap --open "$id" ;  " >> /home/kali/Desktop/project1/p1.3.log
echo "--- whois and nmap data were saved into  /home/kali/Desktop/project1/p1.3.log"
}
da

echo ' '
echo ' '
echo ' '
echo "               *** script made by : izack garcia *** "
