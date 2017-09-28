# sslscan
A proof of concept perl script for scanning your TLS certificates

1. You need to change the hosts.txt, and add your own hosts. One on
each line
2. The hosts.txt needs to be in the same directory as the
scanssl-beta.pl file
3. You need to clone the ssllabs git repository before running this
program: git clone https://github.com/ssllabs/ssllabs-scan.git
4. You need to install the programming language go
5. You need to install the following perl modules: JSON, Date::Parse,
DateTime, File::Copy
6. Run the program: perl scanssl-beta.pl and it should work!
7. When all the hosts have been scanned, view your generated html file
open it in a browser
8. Remember that we work with two repositories to make this work. The
one from SSLLABS which has a name ssllabs-scan, and my repository is
named sslscan. This might be a bit confusing. The sslscan should be
the folder from where you run the code.

Good luck

