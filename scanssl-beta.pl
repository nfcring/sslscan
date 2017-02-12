#!/usr/bin/perl -w
use strict;
use JSON qw( decode_json );
use Date::Parse;
use DateTime;

my $timestamp = localtime(time);
# You need to add your own servers in this array below
my @ips = ('reglund.com','example.com');

# This command assumes that you have a git folder in your home dir
# and have checked out the ssllabs-scan repo into it
system("cd ~/git/ssllabs-scan/ && git pull && rm ./ssllabs-scan && go build ssllabs-scan.go");

# Choose to where you want the html file to go
my $filename = '/where/you/want/the/html/sslscan.html';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

my $html_top = << "END";
<html>
    <head><link rel='stylesheet' type='text/css' href='sslscan.css'></head>
    <body>
      <table>
         <tr>
           <th>Hostname</th><th>TLS grade</th><th>Expiration date</th>
END

print $fh $html_top;

chmod 0644,$filename;

foreach(@ips){
    my $result = `~/git/ssllabs-scan/ssllabs-scan $_`;
    my $decoded = decode_json($result);
    my $jsonfilename = "/uio/kant/div-ceres-u1/asbjornt/www_docs/json/$_.json";
    
    open(my $jfh, '>', $jsonfilename) or die "Could not open file '$jsonfilename' $!";
   
    print $jfh $result;

    close $jfh;
    chmod 0644,$jsonfilename;
    
    my ($host, $grade, $notafter, $date_class);

    if ( $decoded->[0]{endpoints}[0]{grade} ){
	$date_class = "good";
	$host = $decoded->[0]{host};
	$grade = $decoded->[0]{endpoints}[0]{grade};
	my $timestampDateTime = DateTime->from_epoch( epoch => str2time ( $timestamp ));
	my $notafterDateTime = DateTime->from_epoch( epoch => $decoded->[0]{endpoints}[0]{details}{cert}{notAfter}/1000);
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
	<td><a href="http://your/path/to/the/json/$_.json">$host</a></td>
	<td><span class="$class">$grade</span></td>
	<td><span class="$date_class">$notafter</span></td>
    </tr>
END
print $fh $html_middle;
}
my $html_bottom = << "END";
     <tr>
       <td colspan="3">Last updated: $timestamp</td>
     </tr>
   </table>
  </body>
</html>
END
print $fh $html_bottom;
close $fh;
