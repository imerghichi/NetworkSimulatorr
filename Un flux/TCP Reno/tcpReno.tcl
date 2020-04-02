#création de la simulation
set ns [new Simulator]

#noeuds d emission
$ns color 1 Blue 
#noeuds de reception
$ns color 2 Red

#ouvrir tracefiles
set tracefile1 [open out.tr w]
set winfile [open WinFile w]
set queuesize [open QueueSize w]
$ns trace-all $tracefile1

#ouvrir nam tracefile
set namfile [open out.nam w]
$ns namtrace-all $namfile

#definire la procédure de la fin

proc finish {} {
	global ns tracefile1 namfile
	$ns flush-trace
	close $tracefile1
	close $namfile
	exec nam out.nam &
	exit 0
}

#créationdes 6 noeuds

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]


#création des liens entre les noeuds
# type liaison les deux noeuds en jeu bande-passante delai de propagation type
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns simplex-link $n2 $n3 0.3Mb 100ms DropTail
$ns simplex-link $n3 $n2 0.3Mb 100ms DropTail
$ns duplex-link $n3 $n4 0.5Mb 40ms DropTail
$ns duplex-link $n3 $n5 0.5Mb 30ms DropTail

#pour NAM position des noeuds
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns simplex-link-op $n2 $n3 orient right
$ns simplex-link-op $n3 $n2 orient left
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n5 orient right-down
$n0 label "TCP Reno"
$n0 color Blue
$n4 color Red
$ns duplex-link-op $n2 $n3 queuePos 0.5

#definir la taille de queue
$ns queue-limit $n2 $n3 20


#installation de la connexion TCP
set tcp [new Agent/TCP/Reno]
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n4 $sink
$ns connect $tcp $sink
$tcp set fid_ 1
$tcp set packetSize_ 552
$tcp set window_ 100000

#application FTP sur connexion TCP
set ftp [new Application/FTP]
$ftp attach-agent $tcp

$ns at 0.1 "$ftp start"
$ns at 124.0 "$ftp stop"


#procedure plot fenetre (window)
proc plotWindow {tcpSource file} {
	global ns
	set time 0.1
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]
	puts $file "$now $cwnd"
	$ns at [expr $now+$time] "plotWindow $tcpSource $file"
}
$ns at 0.1 "plotWindow $tcp $winfile"

set monitor [$ns monitor-queue $n2 $n3 stdout 0.1]

proc queueLength {sum number file} {
	global ns monitor
	set time 0.1
	set len [$monitor set pkts_]
	set now [$ns now]
	puts $file "$now $len"
	$ns at [expr $now+$time] "queueLength $sum $number $file"
}
$ns at 0.1 "queueLength 0 0 $queuesize"

$ns at 125.0 "finish"
$ns run
