#!/usr/bin/perl -w
use strict;
use JSON qw( decode_json );
use Date::Parse;
use DateTime;

my $start_run = time();
my $timestamp = localtime(time);
# You need to add your own servers in hosts.txt file
my @ips; 
my $hosts_filename = 'hosts.txt';

open(my $fh, '<:encoding(UTF-8)', $hosts_filename)
    or die "Could not open file '$hosts_filename' $!";
 
while (my $row = <$fh>) {
    chomp $row;
    push(@ips,$row);
}

close $fh;

# This command assumes that you have a git folder in your home dir
# and have checked out the ssllabs-scan repo into it
system("cd ~/git/ssllabs-scan/ && git pull && rm ./ssllabs-scan-v3 && go build ssllabs-scan-v3.go");

# Choose to where you want the html file to go
my $filename_tmp = 'sslscan_tmp.html';
my $filename_finished = 'sslscan.html';

open($fh, '>', $filename_tmp)
    or die "Could not open file '$filename_tmp' $!";

my $html_top = << "END";
<html>
    <head><link rel='stylesheet' type='text/css' href='sslscan.css'></head>
    <body>
      <table>
         <tr>
           <th>Hostname</th><th>TLS grade</th><th>Expiration date</th>
END

print $fh $html_top;

chmod 0644,$filename_tmp;

foreach(@ips){    
    my $result = `~/git/ssllabs-scan/ssllabs-scan-v3 $_`; #Enter your own path
    my $decoded = decode_json($result);
    my $jsonfilename = "json/$_.json";
    
    open(my $jfh, '>', $jsonfilename)
	or die "Could not open file '$jsonfilename' $!";
   
    print $jfh $result;
    close $jfh;

    chmod 0644,$jsonfilename;
    
    my ($host, $grade, $notafter, $date_class);

    if ( $decoded->[0]{endpoints}[0]{grade} ){
	$date_class = "good";
	$host = $decoded->[0]{host};
	$grade = $decoded->[0]{endpoints}[0]{grade};
	my $timestampDateTime = DateTime->from_epoch( epoch => str2time ( $timestamp ));
	my $notafterDateTime = DateTime->from_epoch( epoch => $decoded->[0]{certs}[0]{notAfter}/1000);
	$notafterDateTime->set_time_zone('CET');
	$notafter = $notafterDateTime->strftime('%Y-%m-%d');
	my $diff = $notafterDateTime->subtract_datetime($timestampDateTime);
	if(($diff->in_units('months') < 2) and ($diff->in_units('months') > 1)){
	    $date_class = "bad";
	} elsif ($diff->in_units('months') < 1) {
	    $date_class = "ugly";
	}
    } else {
	$host = $_;
	$grade = "Error";
	$notafter = "Error";
	$date_class = "ugly";
    }
    my $class;

    if($grade =~ /^A/) {
	$class="good";
    } elsif($grade =~ /^B/) {
	$class="bad";
    } else {
	$class = "ugly";
    }

# Below you need to enter the url to where you saved your json files 
    my $html_middle = << "END";
    <tr>
	<td><a href="$jsonfilename">$host</a></td>
	<td><span class="$class">$grade</span></td>
	<td><span class="$date_class">$notafter</span></td>
    </tr>
END
print $fh $html_middle;
}

my $end_run = time();

my $run_time = sprintf("%.1f",($end_run - $start_run)/60);

my $html_bottom = << "END";
     <tr>
       <td colspan="3">Last updated: $timestamp, total runtime: $run_time minutes</\
td>
     </tr>
    <tr>
       <td colspan="3">Based on ssllabs.com</td>
    </tr>
   </table>
  </body>
</html>
END

print $fh $html_bottom;
close $fh;

#Copy working file to prod file
use File::Copy;
move($filename_tmp,$filename_finished);
