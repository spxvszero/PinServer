#!/bin/sh

serverName="PinServer"
latestURL="https://github.com/spxvszero/PinServer/releases/latest/download/pin_server_linux"

curDir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

systemdServiceDir="/usr/lib/systemd/system"
systemdServiceFile="/usr/lib/systemd/system/${serverName}.service"
firewallServiceXML="/usr/lib/firewalld/services/${serverName}.xml"

port="8888"
webPort="8885"

function addSystemdService(){

	if ! command -v systemctl &> /dev/null
	then
	    echo "systemctl command could not be found."
	    exit
	fi

	serviceFile="[Unit]
	\nDescription=${serverName}
	\nAfter=network-online.target
	\n\n[Service]
	\nType=simple
	\nExecStart=${curDir}/${serverName}
	\n\n[Install]
	\nWantedBy=multi-user.target
	\n"

	if [[ -e ${systemdServiceDir} ]]; then
	else
		mkdir ${systemdServiceDir}
	fi

	echo -e ${serviceFile} > ${systemdServiceFile}

	systemctl daemon-reload
	systemctl enable ${serverName}

	systemctl start ${serverName}
}

function removeSystemdService(){

	if ! command -v systemctl &> /dev/null
	then
	    echo "systemctl command could not be found."
	    exit
	fi

	systemctl stop ${serverName}
	systemctl disable ${serverName}

	if [[ -e ${systemdServiceFile} ]]; then
		#statements
		rm -f ${systemdServiceFile}
	fi

	systemctl daemon-reload
}


function addFirewallService(){


	if ! command -v firewall-cmd &> /dev/null
	then
	    echo "firewalld command could not be found."
	    exit
	fi


	firewallService="<?xml version=\"1.0\" encoding=\"utf-8\"?>
\n<service>
\n  <short>${serverName}</short>
\n  <description>This server is made for custom services, looking more with site : https://github.com/spxvszero/PinServer</description>
\n  <port protocol=\"tcp\" port=\"${port}\"/>
\n  <port protocol=\"tcp\" port=\"${webPort}\"/>
\n</service>"
	
	echo -e ${firewallService} > ${firewallServiceXML}

	firewall-cmd --reload

	firewall-cmd --add-service=${serverName} --permanent
	firewall-cmd --reload
}

function removeFirewallService(){

	if ! command -v firewall-cmd &> /dev/null
	then
	    echo "firewalld command could not be found."
	    exit
	fi

	firewall-cmd --remove-service=${serverName} --permanent

	if [[ -e ${firewallServiceXML} ]]; then
		#statements
		rm -f ${firewallServiceXML}
	fi

	firewall-cmd --reload

}

function installServer(){
	#check if exist
	if [[ -e ${serverName} ]]; then
		#statements
		echo "${serverName} File exist, skip download..."
	else

		if command -v curl &> /dev/null;then
		    curl -o ${serverName} -L ${latestURL}
		    
		elif command -v wget &> /dev/null; then
			wget -O ${serverName} ${latestURL}

		else
			echo "Download Failed! Try Download yourself : ${latestURL}"
			echo "And retry this script."
			exit
		fi

		
	fi

	chmod +x ${serverName}
	./${serverName}

	addSystemdService
	addFirewallService

	echo "Finished!"
}

function updateServer(){
	#stop server
	systemctl stop ${serverName}

	#download && update
	if command -v curl &> /dev/null;then
	    curl -o ${serverName} -L ${latestURL}
	    
	elif command -v wget &> /dev/null; then
		wget -O ${serverName} ${latestURL}

	else
		echo "Download Failed! Try Download yourself : ${latestURL}"
		echo "And retry this script."
		exit
	fi

	#restart server
	systemctl start ${serverName}
}

function uninstallServer(){
	removeFirewallService
	removeSystemdService
}

function welcomeInfo(){
	echo ""
	echo "** ** ** ** ** ** ** ** ** ** ** **"
	echo ""
	echo "Welcome PinServer Auto Setup Script! "
	echo "Tell me what you want to do :"
	echo ""
	echo "	1. Install"
	echo "	2. Update"
	echo "	3. Uninstall"
	echo ""
	printf "I want to : "
	read input


	if [[ ${input} == "1" ]]; then
		#statement
		installServer
	elif [[ ${input} == "2" ]]; then
		#statements
		updateServer
	elif [[ ${input} == "3" ]]; then
		uninstallServer
	else
		echo "Not Funny, Bye!"
	fi
}



welcomeInfo
