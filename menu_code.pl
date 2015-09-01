#!/usr/bin/perl
	
use strict;

use libstats_db;

my ($libstats_db);

$libstats_db = new libstats_db;

print $libstats_db->{'CGI'}->header('application/javascript');

print "{\n";
print $libstats_db->get_json_tables('libraries'), ',';
print $libstats_db->get_json_tables('library_locations'), ',';
print $libstats_db->get_json_tables('library_patron_types'), ',';
print $libstats_db->get_json_tables('library_question_formats'), ',';
print $libstats_db->get_json_tables('library_question_types'), ',';
print $libstats_db->get_json_tables('library_time_spent_options'), ',';
print $libstats_db->get_json_tables('locations');
print "}\n";
