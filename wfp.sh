#!/bin/bash

echo "******* hello ********"




rootcheck=$(whoami) 

function rc ()
{
 if [ "$rootcheck" == "root" ] 
 then 
 echo " * you are root!"
 else 
 echo " * you are not root. you must be root to run the script. Exiting..."
 exit
 fi 
}
rc

echo "  "

echo " * please place the file in the same directory as the script!!"
read -p " * specify the filename:  " fn

if [ -e "$fn" ] ;
then
echo " * file detected. :)"
else 
echo " * file not found :( . try again "
exit
fi

 
echo "  "

#apps installation 
function instapp() 
{
	for app in binwalk foremost bulk-extractor scalpel ;
	do 
		if command -v  $app > /dev/null;
		then 
		echo " * $app is already installed."
		else 
		echo " * $app is not installed, installing..."
		apt-get install -y $app > /dev/null 2>&1
		fi
	done
 
	if command -v  strings > /dev/null;
	then 
	echo " * strings is already installed."
	else 
	echo " * strings is not installed, installing..."
	apt-get install -y bintils > /dev/null 2>&1
	fi
	
	if [ -f volatility_2.6_lin64_standalone ]
	then
	echo " * volatility is already installed"
	mv volatility_2.6_lin64_standalone vol
	fi
	
	if [ -f vol ]
	then
	echo  " * volatility is already installed"
		
	else
	wget -nc http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip >/dev/null 2>&1
	unzip -j -o volatility_2.6_lin64_standalone.zip >/dev/null 2>&1
		
	mv volatility_2.6_lin64_standalone vol
	echo " * volatility is now installed" 
	fi
}
instapp
echo " "
chmod 777 vol
# data carving
pth=$(pwd)
function carvers ()
{
	echo " * extracting with binwalk..."
	mkdir -p report-and-findings
	nf="report-and-findings"
	chmod 777 $nf
	rm -rf binout
	rm -rf binlog.txt
	binwalk $fn -f $pth/$nf/binlog.txt > /dev/null
	sleep 2
	echo " * extracting with bulk extractor..."
	rm -rf bulkout
	bulk_extractor $fn -o $pth/$nf/bulkout > /dev/null
	sleep 1
	echo " * extracting with strings..."
	rm -rf stringsout.txt
	strings $fn > $pth/$nf/stringsout.txt 
	sleep 1
	#echo " * extracting with foremost..."
	cd report-and-findings
	rm -rf output 
	#foremost -Q -i "$fn" -t all -o foreout  > /dev/null 2>&1 (for some reason doest work but the command is correct)
	
	echo " * files have been extracted in to project2 directory"
}
carvers

echo " "


#detecting network file

echo " * checking for network files..."
cd bulkout
if [ -f "packets.pcap" ]; 
then
	
		path=$(pwd)
		fz=$(du -h packets.pcap | awk '{print $1}')
		echo -e " * network file found :).\n * File name: packets.pcap. \n * File location: $path .\n * File size: $fz. " | tee -a $pth/$nf/Report.txt
		
else
		echo " * network File not found. :("
fi

echo " "
	
cd ..

#human readable

function hr ()
{ 
echo " * extracting human-readables to ./human-readable..."
mkdir -p ./human-readable > /dev/null
cd ..
strings_commands='username user passwords password exe http'

for i in $strings_commands
 do
  strings $fn | grep -i "$i" > "$pth/$nf/human-readable/$i.txt" 
done

strings $fn | grep -i '@' | grep -i '.com' >> $pth/$nf/human-readable/email.txt

}
hr

#volatility
function vol ()
{
if  [ -z "$(./vol -f  $fn imageinfo 2>/dev/null | grep 'No suggestion' 2>/dev/null)"  ]  
then 
	echo " * file compatible with volatility"
		profile=$(./vol -f $fn imageinfo 2>/dev/null | grep 'Suggested Profile(s)' 2>/dev/null | awk '{print $4}' | awk 'BEGIN {FS=","} {print $1}' 2>/dev/null)
		
#volatility execution and basic information extraction
		 
		#extracting running processes
		x='pslist pstree psscan connscan sockets connections'
	
	for i in $x
	do
		w=$(./vol -f $fn  --profile=$profile $i 2>/dev/null )
		echo "$w" > $pth/$nf/vol_$i
	done 	
		#registry extraction
		
		cd $nf
		mkdir -p regdump
		cd regdump
		lo=$(pwd)
		cd ..
		cd ..
		./vol -f $fn --profile=$profile dumpregistry -D $lo > /dev/null 2>&1
		
		cd $pth
		x='hashdump hivescan lsadump userassist shellbags hivelist'
		for i in $x
		do
		w=$(./vol -f $fn --profile=$profile $i  2>/dev/null )
		echo "$w" >  $lo/vol_$i
		done
		
	
 else 
	echo " * file not compatible with volatility"
fi	
}
vol

echo " "

cd $pth
for i in $(find $nf -type f -empty)
	do 
		
		rm $i 2>/dev/null
	done
	
echo " * Removing empty files"


echo -e " * forensics analysis for:  $fn. \n * script executed: $(stat -c %y $pth/$nf). " | tee -a $nf/Report.txt
echo -e " * extracted files saved into diractory: $pth/$nf. \n * extracted files: $(find $nf -type f | wc -l)." | tee -a $nf/Report.txt

zip -qr "${fn}_analisis.zip" "$nf" 
chmod 777 "${fn}_analisis.zip"
echo "A zip file has been created of the findings. Zip name: ${fn}_analisis.zip"
#rm $nf 2>/dev/null















