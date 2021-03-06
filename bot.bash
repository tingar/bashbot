#!/usr/bin/env bash

if [ ! -f config ] ; then
	cat >config <<-EOF
    IRCD=irc.freenode.com
    IRCPORT=6697
    BOTNAME=bashbot
    IRCCHANNEL=#bashbot-test
EOF
fi

source config

LOGFILE=bot.log

line=""
started=""
test -e botfile && rm botfile
mkfifo botfile || exit 2 

NETCAT="socat - OPENSSL:$IRCD:$IRCPORT,cipher=ALL:-LOW:@STRENGTH,method=TLS1.2,verify=0"
#NETCAT="nc $IRCD $IRCPORT"

tail -f botfile | $NETCAT | while true ; do
	if [ -z $started ] ; then
		echo "Logging in: ${IRCD}:${IRCPORT} ${BOTNAME}"
		echo "USER ${BOTNAME} 0 ${BOTNAME} :I iz a bot" >> botfile
		echo "NICK ${BOTNAME}" >> botfile
		echo "MODE +B" >> botfile
		echo "JOIN ${IRCCHANNEL} ${IRCPW}" >> botfile
    if [[ "${AUTOCMD}" ]] ; then
      echo "${AUTOCMD}" >> botfile
    fi
		started="yes"
	fi
	read irc
	echo "> ${irc}" >>${LOGFILE}
	case `echo "$irc" | cut -d " " -f 1` in
		"PING") echo "PONG :`hostname`" >> botfile ;;
	esac
	#echo $irc
	chan=`echo "$irc" | cut -d ' ' -f 3`
	barf=`echo "$irc" | cut -d ' ' -f 1-3`
	cmd=`echo "${irc##$barf :}"|cut -d ' ' -f 1|tr -d "\r\n"`
	args=`echo "${irc##$barf :$cmd}"|tr -d "\r\n"`
	nick="${irc%%!*}";nick="${nick#:}"
	if [ "`echo "$cmd" | cut -c1`" == "!" ] ; then
		echo "Got command $cmd from channel $chan with arguments $args"
	fi
	case $cmd in
		"!add") line="$args $line" ;;
		"!list")
			echo ">$chan :$line" >>${LOGFILE}
			echo "PRIVMSG $chan :$nick:$line" >> botfile
			;;
	esac
done
