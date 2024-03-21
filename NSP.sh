#!/bin/bash
# Script for network security

echo " ******* honey pot script *******
made by : izack garcia"

# Create a directory to store files
od="network_security"
mkdir -p "$od"

# Change to the script's directory
cd "$(dirname "$0")"

# Create an empty file for storing captured information
touch captured_info.txt

# Prompt the user to choose a service
read -p "Choose a service:
1. HTTP
2. TELNET
3. FTP
4. Start all services
 > Enter your chosen number: " Services

echo "  " 
# Define file paths for output and log files
output_file="$od/captured_info.txt"
log_file="$od/script_log.txt"
mkdir -p "$od"
touch "$log_file"

# time logging
get_current_time() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Function to log output and move captured info to the log file
log_output() {
    echo > "$log_file"
    cat "$output_file" >> "$log_file"
    rm -f "$output_file"
}

# Analyze the attacker's IP address using Metasploit based on user choice
case $Services in
    1)
        # Execute Metasploit for HTTP
        echo " * Preparing to execute Metasploit for HTTP... This may take 30 seconds."
        sleep 2
        echo " * Executing Metasploit for HTTP..."
        msfconsole -q -x "use auxiliary/server/capture/http; exploit -j; sleep 100; exit;" 2>&1 | awk '/HTTP/ { sub(/.*HTTP/, ""); time=strftime("%Y-%m-%d %H:%M:%S"); printf "%s HTTP %s\n", time, $0; }' | tee -a "$output_file"
        ;;
    2)
        # Execute Metasploit for TELNET
        echo " * Preparing to execute Metasploit for TELNET... This may take 100 seconds."
        sleep 2
        echo " * Executing Metasploit for TELNET..."
        msfconsole -q -x "use auxiliary/server/capture/telnet; exploit -j; sleep 100; exit;" 2>&1 | awk '/TELNET/ { sub(/.*TELNET/, ""); time=strftime("%Y-%m-%d %H:%M:%S"); printf "%s TELNET %s\n", time, $0; }' | tee -a "$output_file"
        ;;
    3)
        # Execute Metasploit for FTP
        echo " * Preparing to execute Metasploit for FTP... This may take 100 seconds."
        sleep 2
        echo " * Executing Metasploit for FTP..."
        msfconsole -q -x "use auxiliary/server/capture/ftp; exploit -j; sleep 100; exit;" 2>&1 | awk '/FTP/ { sub(/.*FTP/, ""); time=strftime("%Y-%m-%d %H:%M:%S"); printf "%s FTP %s\n", time, $0; }' | tee -a "$output_file"
        ;;
    4)
        # Execute Metasploit for all services
        echo " * Preparing to execute Metasploit for all services... This may take 100 seconds."
        sleep 2
        echo " * Executing Metasploit for all services..."
        {
            msfconsole -q -x "use auxiliary/server/capture/http; exploit -j; sleep 100; exit;" 2>&1 | awk '/HTTP/ { sub(/.*HTTP/, ""); time=strftime("%Y-%m-%d %H:%M:%S"); printf "%s HTTP %s\n", time, $0; }' &
            pid_smb=$!

            msfconsole -q -x "use auxiliary/server/capture/telnet; exploit -j; sleep 100; exit;" 2>&1 | awk '/TELNET/ { sub(/.*TELNET/, ""); time=strftime("%Y-%m-%d %H:%M:%S"); printf "%s TELNET %s\n", time, $0; }' &
            pid_telnet=$!

            msfconsole -q -x "use auxiliary/server/capture/ftp; exploit -j; sleep 100; exit;" 2>&1 | awk '/FTP/ { sub(/.*FTP/, ""); time=strftime("%Y-%m-%d %H:%M:%S"); printf "%s FTP %s\n", time, $0; }' &
            pid_ftp=$!

            wait $pid_smb
            wait $pid_telnet
            wait $pid_ftp
        } | tee -a "$output_file"

        echo "   "
        echo " * MSFConsole analysis complete. Information is in the log file."
        ;;
    *)
        # Invalid choice
        echo " - Invalid choice. Exiting."
        exit 1
        ;;
esac

# logging content 
log_output

echo "   "
# ip addresses into variables
ip_addresses=$(grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' "$log_file" | sort -u)

# Executing commands for each IP address
echo > "scan_file.txt"
for ip in $ip_addresses; do
    echo >> "scan_file.txt"  # Clear the scan file for each iteration

    # searching with NMAP
    echo " * Scanning with NMAP for $ip..."
    echo "****** NMAP Results for $ip ******" >> "scan_file.txt"
    nmap -sV $ip >> "scan_file.txt"
    echo >> "scan_file.txt" 

    # searching with WOHIS
    echo " * Performing WHOIS lookup for $ip..."
    echo "****** WHOIS Results for $ip ******" >> "scan_file.txt"
    whois $ip >> "scan_file.txt"
    echo >> "scan_file.txt"  
done

