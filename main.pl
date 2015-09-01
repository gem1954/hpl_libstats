#!/usr/bin/perl
	
use strict;

use libstats_db;

my ($libstats_db, $main_template, %page_data, $query, $table_maps_HR);

$libstats_db = new libstats_db;

$main_template = 'main.html';

$table_maps_HR = $libstats_db->get_table_maps();

$query = "select * from questions order by question_date desc limit 15;";

#$page_data{'main'} .= "$query<br>";

foreach my $table (sort keys %$table_maps_HR)
{
	$page_data{'main'} .= "<div><b>$table</b></div>\n";
	my $table_AR = $table_maps_HR->{$table};
	foreach my $table_row_HR (@$table_AR)
	{
		$page_data{'main'} .= "<div>$table_row_HR</div>\n";
		foreach my $field (sort keys %{$table_row_HR})
		{
			$page_data{'main'} .= "<div>$field: $table_row_HR->{$field}</div>\n";
		}
	}
	$page_data{'main'} .= "<hr>\n";
}
{
	my ($return, $sth) = $libstats_db->get_sth($query);
	#$page_data{'main'} .= "$return, $sth<br>";
	if($return > 0)
	{
		$page_data{'main'} .= "<pre>\n";
		while (my $record_HR = $sth->fetchrow_hashref)
		{
			#$page_data{'main'} .= "<p>$record_HR->{'question_id'}, $record_HR->{'question'}</p>";
			foreach my $key (sort keys %{$record_HR})
			{
				$page_data{'main'} .= "\t$key = $record_HR->{$key}\n";
			}
			$page_data{'main'} .= "<hr>\n";
		}
		$page_data{'main'} .= "</pre>\n";
	}
}

#$page_data{'main'} .= sprintf("<pre>%s</pre>", $libstats_db->get_json_tables('libraries'));

$libstats_db->send_page($main_template, \%page_data);

__DATA__
use CGI;use CGI::Carp 'fatalsToBrowser';

use DBI;

my($cgi, $page_src, $page_data_HR, $page_template, $page,
	$database, $username, $passwd, $dbh, $query, $sth);

$cgi = new CGI;

### database section ### hpl_libstats_o(
$database = 'hpl_libstats'; 
$username = 'hpl_libstats_o'; 
$passwd = 'bilTeneck';

### Data setup ###
$dbh = DBI->connect("DBI:mysql:${database}:localhost", $username, $passwd)
    or die "No Handle $DBI::errstr\n";


$page_src = 'main.html';

$query = "select * from questions limit 50;";
$sth = $dbh->prepare($query);



$sth->execute();
while (my $record_HR = $sth->fetchrow_hashref)
{
	$page_data_HR->{'main'} .= "<p>$record_HR->{'question'}</p>";
}


$page_template = &get_template($page_src);

$page = &run_template($page_template, $page_data_HR);

print $cgi->header(), $page;

sub get_template
{
	my ($source, $FH, $template);
	$source = shift;
	open($FH, '<', $source);
	while (my $line = <$FH>)
	{
		$template .= $line;
	}
	return $template;
}
sub run_template
{
	my ($template, $data_HR);
	($template, $data_HR) = @_;
	$template =~ s/\[\[\$([^\]]+)\]\]/&do_var($1, $data_HR)/eg;
	return $template;
}

sub do_var
{
	my ($var, $data_HR);
	($var, $data_HR) = @_;
	if (exists $data_HR->{$var})
	{
	    return $data_HR->{$var};
	}
	else
	{
		return "[[\$$var]]";
	}
}
