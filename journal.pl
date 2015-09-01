#!/usr/bin/perl
	
use strict;

use libstats_db;

my ($libstats_db, $main_template, %page_data, $insert_err, 
	$table_maps_HR, $patron_types_HR, $question_types_HR, $time_spent_types_HR, $question_format_types_HR, $location_id_types_HR,
	$locations_HR, $question_type_HR, $row_template);

$libstats_db = new libstats_db;

# defs
{
	$main_template = 'journal.html';

	$row_template = '
	<tr>
		<td>[[$Edit]]</td>
		<td>[[$Patron Type]]</td>
		<td>[[$Question Type]]</td>
		<td>[[$Question Format]]</td>
		<td>[[$Location]]</td>
		<td>
		<div class = "que"><b>Q:</b> [[$question]]</div>
		<div class = "ans"><b>A:</b> [[$answer]]</div></td>
		<td>[[$question_date]]</td>
		<td><span class="initials">[[$initials]]</span></td>
	</tr>
	';
}

{ # map useful data
	$table_maps_HR = $libstats_db->get_table_maps();

	foreach my $patron_type_HR (@{$table_maps_HR->{'patron_types'}})
	{
		$patron_types_HR->{$patron_type_HR->{'patron_type_id'}} = $patron_type_HR->{'patron_type'};
		#$page_data{'main'} .= "$patron_type_HR||| $patron_type_HR->{'patron_type_id'} = $patron_type_HR->{'patron_type'}<br>\n";
	}
	foreach my $location_HR (@{$table_maps_HR->{'library_locations'}})
	{
		$location_id_types_HR->{$location_HR->{'location_id'}}{$location_HR->{'library_id'}} = $location_HR->{'location_name'};
		#$page_data{'main'} .= "$location_HR->{'location_id'} $location_HR->{'library_id'} = $location_HR->{'location_name'}<br>\n";
	}
	{
		my $tmp_HR = $table_maps_HR->{'questionType'}[0];
		foreach my $key (keys %{$tmp_HR})
		{
			$question_types_HR->{$key} = $tmp_HR->{$key};
		}
	}
	{
		my $tmp_HR = $table_maps_HR->{'timeSpent'}[0];
		foreach my $key (keys %{$tmp_HR})
		{
			$time_spent_types_HR->{$key} = $tmp_HR->{$key};
		}
	}
	{
		my $tmp_HR = $table_maps_HR->{'questionFormat'}[0];
		foreach my $key (keys %{$tmp_HR})
		{
			$question_format_types_HR->{$key} = $tmp_HR->{$key};
		}
	}
	{
		my $tmp_HR = $table_maps_HR->{'location'}[0];
		foreach my $key (keys %{$tmp_HR})
		{
			$locations_HR->{$key} = $tmp_HR->{$key};
		}
	}
	{
		my $tmp_HR = $table_maps_HR->{'questionType'}[0];
		foreach my $key (keys %{$tmp_HR})
		{
			$question_type_HR->{$key} = $tmp_HR->{$key};
		}
	}
}

# receive form response
{
	my(%values, $found, $query);
	#if(my $start_id = $libstats_db->param('start_id'))
	foreach my $param ('answer', 'question', 'backdate', 'initials', 'question_format', 'time_spent', 'question_type', 'patron_type', 'location')
	#foreach my $param ($libstats_db->{'CGI'}->param())
	{
		#$page_data{'form'} .= "test $param<br>";
		if(my $val = $libstats_db->param($param))
		{
			$values{$param} = $val;
			$found++;
			#$page_data{'form'} .= "  -|- $val<br>";
		}
	}
	if($found)
	{
		if(0)
		{
			$page_data{'form'} = '';
			foreach my $key (sort keys %values)
			{
				$page_data{'form'} .= "$key = $values{$key}<br>\n";
			}
			$page_data{'form'} .= "found $found<br>";
		}
		$query = "INSERT INTO questions 
		(
			library_id, location_id, question_type_id, time_spent_id, 
			referral_id, patron_type_id, question_format_id, initials, 
			question_date, client_ip, 
			user_id, answer, question, 
			date_added
		) 
		VALUES
		(
			'<library_id>', '<location_id>', '<question_type_id>', '<time_spent_id>', 
			'0', '<patron_type_id>', '<question_format_id>', '<initials>', 
			'<question_date>', '<client_ip>', 
			'<user_id>', '<answer>', '<question>', 
			'<date_added>'
		);";
		$query = "INSERT INTO questions 
		(
			library_id, location_id, question_type_id, time_spent_id, 
			referral_id, patron_type_id, question_format_id, initials, 
			question_date, client_ip, 
			user_id, answer, question, 
			date_added
		) 
		VALUES
		(
			?, ?, ?, ?, 
			?, ?, ?, ?, 
			?, ?, 
			?, ?, ?, 
			?
		);";
		#'<library_id>', '<location_id>', '<question_type_id>', '<time_spent_id>', 
		#	'0', '<patron_type_id>', '<question_format_id>', '<initials>', 
		#	'<question_date>', '<client_ip>', 
		#	'<user_id>', '<answer>', '<question>', 
		#	'<date_added>'
		
		#$values{''} = $values{''};
		$values{'question_type_id'} = $values{'question_type'};
		$values{'time_spent_id'} = $values{'time_spent'};
		$values{'patron_type_id'} = $values{'patron_type'};
		$values{'date_added'} = $libstats_db->format_date('today', '%Y-%m-%d %H:%M');
		$values{'library_id'} = 1;
		$values{'location_id'} = $values{'location'};
		$values{'question_format_id'} = $values{'question_format'};
		$values{'client_ip'} = $ENV{'REMOTE_ADDR'};
		$values{'user_id'} = $ENV{'REMOTE_USER'};
		if($values{'backdate'} =~ /\S/)
		{
			$values{'question_date'} = $libstats_db->format_date($values{'backdate'}, '%Y-%m-%d %H:%M');
		}
		else
		{
			$values{'question_date'} = $libstats_db->format_date('today', '%Y-%m-%d %H:%M');
		}
		
		#$query =~ s/<([^>]+)>/$values{$1}/g;
		
		#$page_data{'form'} .= "<pre>\n$query\n</pre>\n";
		
		#$libstats_db->get_sth($query);
		unless($libstats_db->insert_sql($query,
			$values{'library_id'}, $values{'location_id'}, $values{'question_type_id'}, $values{'time_spent_id'}, 
			'0', $values{'patron_type_id'}, $values{'question_format_id'}, $values{'initials'}, 
			$values{'question_date'}, $values{'client_ip'}, 
			$values{'user_id'}, $values{'answer'}, $values{'question'}, 
			$values{'date_added'}))
		{
			my($cgi);
			$cgi = $libstats_db->{'CGI'};
			$page_data{'form'} = $cgi->h2('An error has prevented inserting this entry into the database.');
			$page_data{'form'} .= $cgi->p('Please return to the form with the back button and correct the error.');
			$insert_err++;
		}
		
	}
}

# entry form
unless($insert_err)
{
	my($cgi);
	
	$cgi = $libstats_db->{'CGI'};
	
	$page_data{'form'} .= $cgi->start_form(
		#-method=>'POST',
		-action=>'journal.pl',
	);
	
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Location') .
		$cgi->popup_menu(
			-name=>'location',
			-values=>['', sort {$locations_HR->{$a} cmp $locations_HR->{$b}} keys %{$locations_HR}],
			-default=>[],
			-labels=>$locations_HR,
		 ) .
		"</div>";
		
		
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Patron Type') .
		$cgi->popup_menu(
			-name=>'patron_type',
			-values=>['', sort {$patron_types_HR->{$a} cmp $patron_types_HR->{$b}} keys %{$patron_types_HR}],
			-default=>[],
			-labels=>$patron_types_HR,
		 ) .
		"</div>";
	
	
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Question Type') .
		$cgi->popup_menu(
			-name=>'question_type',
			-values=>['', sort {$question_type_HR->{$a} cmp $question_type_HR->{$b}} keys %{$question_type_HR}],
			-default=>[],
			-labels=>$question_type_HR,
		 ) .
		"</div>";

	
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Time Spent') .
		$cgi->popup_menu(
			-name=>'time_spent',
			-values=>['', sort {$time_spent_types_HR->{$a} cmp $time_spent_types_HR->{$b}} keys %{$time_spent_types_HR}],
			-default=>[],
			-labels=>$time_spent_types_HR,
		 ) .
		"</div>";
		
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Question Format') .
		$cgi->popup_menu(
			-name=>'question_format',
			-values=>['', sort {$question_format_types_HR->{$a} cmp $question_format_types_HR->{$b}} keys %{$question_format_types_HR}],
			-default=>[],
			-labels=>$question_format_types_HR,
		 ) .
		"</div>";
		
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Initials') .
		$cgi->textfield(-name=>'initials',
		    -value=>'',
		    -size=>12,
		    -maxlength=>12) .
		"</div>";
		
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Backdate') .
		$cgi->textfield(-name=>'backdate',
		    -value=>'',
		    -size=>24,
		    -maxlength=>24) .
		"</div>";
	
	$cgi->param('question', '');
	$page_data{'form'} .= 
		qq(<div class="inputBox">) .
		$cgi->h5('Question') .
		$cgi->textarea(-name=>'question',
			  -default=>'',
			  -rows=>5,
			  -columns=>80)# .
		;#"</div>";
	
	$cgi->param('answer', '');	
	$page_data{'form'} .= 
		#qq(<div class="inputBox">) .
		$cgi->h5('Answer') .
		$cgi->textarea(-name=>'answer',
			  -default=>'',
			  -rows=>5,
			  -columns=>80)# .
		;#"</div>";
		
	$page_data{'form'} .= 
		#qq(<div class="inputBox">) .
		qq(<br>) .
		$cgi->submit(-name=>'send',
			-value=>'Save Question / Answer') .
		"</div>";
		
	$page_data{'form'} .= $cgi->end_form;
}

# journal listing
{
	my($where, $limit, $query);
	if(my $start_id = $libstats_db->param('start_id'))
	{
		#question_id
		$where = "where question_id <= $start_id";
	}
	$limit = 50;
	{
		my($cgi);
		$cgi = $libstats_db->{'CGI'};
		$page_data{'journal'} .=
			qq(<div class="pager">\n) .
			$cgi->b('Jump To') .
			$cgi->start_form(
				-action=>'journal.pl') .
			$cgi->textfield(-name=>'start_id',
				-value=>'',
				-size=>10,
				-maxlength=>10) .
			$cgi->submit(-name=>'send',
				-value=>'Go') .
			$cgi->end_form .
			qq(</div>\n)
		;
	}

	$query = "select 
		question_id, patron_type_id, question_type_id, time_spent_id, question_format_id, location_id, library_id, question, answer, initials, 
		DATE_FORMAT(question_date, '%m/%d/%Y %l:%i %p') question_date
	from questions $where order by question_id desc limit $limit;";

	$page_data{'journal'} .= "<!-- \n$query\n -->\n";

	{
		my ($return, $sth, $row) = $libstats_db->get_sth($query);
		#$page_data{'main'} .= "$return, $sth<br>";
		if($return > 0)
		{
			$page_data{'journal'} .= "<table border=\"1\">\n
			<tr>
				<th>Edit</th>	
				<th>Patron Type</th>
				<th>Question Type</th>	
				<th>Question Format</th>	
				<th>Location</th>	
				<th>Question / Answer</th>
				<th>Date</th>
				<th>Initials</th>
			</tr>";
			while (my $record_HR = $sth->fetchrow_hashref)
			{
				#$record_HR->{'Edit'} = sprintf(qq(<a href="edit_entry.pl?question_id=%s">%s</a>), $record_HR->{'question_id'}, $record_HR->{'question_id'});
				$record_HR->{'Edit'} = $record_HR->{'question_id'};
				$record_HR->{'Patron Type'} = $patron_types_HR->{$record_HR->{'patron_type_id'}};
				$record_HR->{'Question Type'} = "$question_types_HR->{$record_HR->{'question_type_id'}}<br>$time_spent_types_HR->{$record_HR->{'time_spent_id'}}";
				$record_HR->{'Question Format'} = $question_format_types_HR->{$record_HR->{'question_format_id'}};
				$record_HR->{'Location'} = $location_id_types_HR->{$record_HR->{'location_id'}}{$record_HR->{'library_id'}};

				$row = $row_template;
				$row =~ s/\[\[\$([^\]]+)\]\]/$record_HR->{$1}/g;
				$page_data{'journal'} .= $row;
			}
			$page_data{'journal'} .= "</table>\n";
		}
	}
	

}


$libstats_db->send_page($main_template, \%page_data);


