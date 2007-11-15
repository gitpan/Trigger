use strict;
use Test::More tests => 5;
use Trigger;

my $trigger = Trigger->new(
		inline_states => {
			heap		=> {test=>'ok'}, 
			init		=> sub {
				my $heap = shift;
				ok( $heap->{test} eq 'ok' );
			},
			process		=>	sub {
				my $context = shift;
				my $heap = $context->heap;
				my ($timestamp, $path) = @_;
				$heap->{path} = $path;
				return 123;
			},
			trigger_and_action => [
				sub { # trigger
					my $context = shift;
					my $heap = $context->heap;
					my @args = @_;
					$heap->{path} =~ /^\/$/ ? return ('TRUE',$args[0]) : return;
				} => sub { # action
					my $context = shift;
					my $heap = $context->heap;
					return join '-' => 'document_root', @_;
				},
				sub { # trigger
					my $context = shift;
					my $heap = $context->heap;
					($_[0] == 123) and 
					$heap->{path} =~ /index/ ? return 0 : return;
				} => sub { # action
					my $context = shift;
					my $heap = $context->heap;
					$heap->{test} = 'OK';
					return join '-' => 'index', @_;;
				},
			],
			end		=>	sub {
				my $context = shift;
				my $heap = $context->heap;
				ok( $heap->{test} eq 'OK' );
			},
		}
	);

	my $loop = 0;
	while ( <DATA> ){
		chomp;
		$_ or last;
		$loop++;
		my @args = /(\[[^]]+\]) "GET (\S+) (\S+)" (\d+) (\d+)/;
		my @result = $trigger->eval(@args) or last;
		my $result = shift @result;
		$loop == 1 and do {ok($result == 123, '$result == 123 : '. $result)};
		$loop == 2 and do {ok($result eq 'document_root-TRUE-123', '$result eq document_root : '. $result)};
		$loop == 3 and do {ok($result eq 'index-0', '$result eq index : '. $result)};
	}


__DATA__
[08/Nov/2007:09:58:27] "GET /favicon.ico HTTP/1.1" 404 397
[08/Nov/2007:12:11:48] "GET / HTTP/1.1" 200 1112
[08/Nov/2007:12:11:50] "GET /index.html HTTP/1.1" 200 2283
[08/Nov/2007:12:53:49] "GET / HTTP/1.1" 200 1112


