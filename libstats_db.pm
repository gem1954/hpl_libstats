package libstats_db;

use lib '/export/home/gegglest/perl_lib';

use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';

use Date::Manip;
&Date_Init("TZ=CST");

use DBI;

my($database, $username, $passwd, %field_map, %common_templatex);

#$cgi = new CGI;

### database section ### hpl_libstats_o(
$database = 'hpl_libstats'; 
$username = 'hpl_libstats_o'; 
$passwd = 'bilTeneck';

%field_map = (
	'admin' => ['parent_table', 'parent_pk', 'descriptor', 'display_name', 'parent_finder', 'edit_action_class', 'bridge_table', 'bridge_table_view'],
	'cookie_logins' => ['cookie_login_id', 'cookie', 'user_id', 'date_last_used'],
	'help_list' => ['help_id', 'description', 'related_table', 'help_name'],
	'libraries' => ['library_id', 'full_name', 'short_name',],
	'library_locations' => ['location_id', 'library_id', 'location_name', 'list_order'],
	'library_patron_types' => ['patron_type_id', 'library_id', 'list_order'],
	'library_question_formats' => ['question_format_id', 'library_id', 'list_order'],
	'library_question_types' => ['question_type_id', 'library_id', 'list_order'],
	'library_time_spent_options' => ['time_spent_id', 'library_id', 'list_order'],
	'locations' => ['location_id', 'location_name', 'parent_list', 'description', 'examples'],
	'patron_types' => ['examples', 'description', 'patron_type_id', 'patron_type', 'parent_list'],
	'questions' => ['backup', 'updated', 'question_id', 'library_id', 'location_id', 'question_type_id', 'question_type_other', 'time_spent_id', 'referral_id', 'patron_type_id', 'question_format_id', 'initials', 'hide', 'obsolete', 'question_date', 'client_ip', 'user_id', 'answer', 'question', 'delete_hide', 'date_added'],
	'reports' => ['report_id', 'report_name', 'report_description', 'report_class'],
	'time_spent_options' => ['examples', 'time_spent_id', 'time_spent'],
	'users' => ['user_id', 'username', 'password', 'library_id', 'active', 'admin'],
);

# this is not used
%common_templatex = (
    widset_1 => qq(<div class="widset_1"><div class="label">%s</div><div class="widget">%s</div><div class="err">%s</div></div>\n),
    widset_1a => qq(<div class="widset_1a"><div class="label">%s</div><div class="widget">%s</div><div class="err">%s</div></div>\n),
    widset_2 => qq(<div class="widset_2"><div class="label">%s</div><div class="widget">%s</div><div class="err">%s</div></div>\n),
    info_1 => qq(<div class="info_1"><div class="heading">%s</div><div class="body">%s</div></div>\n),
    table_2 => qq(<tr><td><b>%s</b></td><td>%s</td></tr>\n),
    table_2_2 => qq(<tr><td><b>%s</b></td><td>%s</td><td><b>%s</b></td><td>%s</td></tr>\n),
);

=head3 New object for Web Application

This sets up a Perl object for webserver use.

	use strict;
	use libstats_db;
	my ($libstats_db);
	$libstats_db = new libstats_db;

Might set up another constructor for non-web use.
=cut

sub new
{
    my ($class, $self);
    $class = shift;
    $self = {};
    bless $self, $class;
    $self->{'CGI'} = new CGI;
	### Data setup ###
	$self->{'dbh'} = DBI->connect("DBI:mysql:${database}:localhost", $username, $passwd)
    or die "No Handle $DBI::errstr\n";
    #$self->{'common_template'} = \%common_template;
    return $self;
}

=head3 params

Pass call to params to CGI module.

=cut

sub param
{
    my($self, $param, $value);
    ($self, $param, $value) = @_;
	if($value =~ /\S/)
	{
		return $self->{'CGI'}->param($param, $value);
	}
	else
	{
		return $self->{'CGI'}->param($param);
	}
}

=head3 Get Template

Get a page template from the filesystem. This will recursivly load sub-templates.

=cut

sub get_template
{
    my($self, $template, $FH, $page);
    ($self, $template) = @_;
    open($FH, '<', $template);
    while(my $line = <$FH>)
    {
        $page .= $line;
    }
    $page =~ s/\[\{([^\}]+)\}\]/$self->get_template($1)/eg;
    return $page;
}

=head3 Send Page

Given a template name and page data as a hashref, print a page.

=cut

sub send_page
{
    my($self, $template, $data_HR, $FH, $page);
    ($self, $template, $data_HR) = @_;

    $page = $self->get_template($template);
    
    $page =~ s/\[\[\$([^\]]+)\]\]/$data_HR->{$1}/g;
    if(exists $self->{'COOKIE'})
    {
        print $self->{'CGI'}->header(-cookie=>$self->{'COOKIE'});
    }
    else
    {
        print $self->{'CGI'}->header;
    }
    print $page;
}

=head3 Get database statement handle.

Given a query, return a statement handle to get returned info.

=cut

sub get_sth
{
	my($self, $query, $sth, $return);
	($self, $query) = @_;
	
	$sth = $self->{'dbh'}->prepare($query);

	$return = $sth->execute();

	return($return, $sth);
	#while (my $record_HR = $sth->fetchrow_hashref)
}

=head3 Insert data

Given a query and some data, insert a row.

=cut

sub insert_sql
{
	my($self, $query, @data, $sth, $return);
	($self, $query, @data) = @_;
	
	$sth = $self->{'dbh'}->prepare($query);

	$return = $sth->execute(@data);
	
	if($return)
	{
		return($return, $sth);
	}
	else
	{
		return undef;
	}
	#while (my $record_HR = $sth->fetchrow_hashref)
}

=head3 Get table maps

Return code.

=cut

sub get_table_maps
{
	my($self, %table_maps);
	($self) = @_;
	foreach my $table (keys %field_map)
	{
		my($query, $sth, $return);
		next if($table eq 'questions');
		next if($table eq 'cookie_logins');
		$query = "select * from $table";
		($return, $sth) = $self->get_sth($query);
		if($return > 0)
		{
			
			while (my $record_HR = $sth->fetchrow_hashref)
			{
				my %table_row;
				foreach my $field (@{$field_map{$table}})
				{
					$table_row{$field} = $record_HR->{$field};
				}
				push(@{$table_maps{$table}}, \%table_row);
			}
			
		}
	}
	push(@{$table_maps{'location'}}, 
	{
		5 => 'Reference Desk', 
		6 => 'Welcome Desk', 
		9 => 'Imaging Lab', 
		3 => 'E-mail Reference', 
		7 => 'Off Desk', 
	});
	push(@{$table_maps{'patronType'}}, 
	{
		3 => 'Patron',
		2 => 'HPL Staff',
		1 => 'City Employee',
	});
	push(@{$table_maps{'questionType'}}, 
	{
		8 => 'Door Count', 
		1 => 'Directional', 
		2 => 'Reference', 
		3 => 'Green Sheet', 
		9 => 'Tour', 
		4 => 'Card Issued'
	});
	push(@{$table_maps{'timeSpent'}}, 
	{
		1 => '0-9 minutes', 
		2 => '10+ minutes'
	});
	push(@{$table_maps{'questionFormat'}}, 
	{
		1 => 'Walk-Up', 
		2 => 'Email', 
		3 => 'Phone'
	});

	#$table_maps{'questionType'} = {8 => 'Door Count', 1 => 'Directional', 2 => 'Reference', 3 => 'Green Sheet', 9 => 'Tour', 4 => 'Card Issued'};
	#$table_maps{'timeSpent'} = {1 => '0-9 minutes', 2 => '10+ minutes'};
	#$table_maps{'questionFormat'} = {1 => 'Walk-Up', 2 => 'Email', 3 => 'Phone'};

	return \%table_maps;
}

=head3 Get JSON for table selected tables.

Return code.

=cut

sub get_json_tables
{
	my($self, $table, $query, $sth, $return, $json);
	($self, $table) = @_;
	
	if(exists $field_map{$table})
	{
		$query = "select * from $table;";
	}
	else
	{
		return;
	}
	#$json .= $query;
	($return, $sth) = $self->get_sth($query);
	#$json .= " $return|$sth\n";
	if($return > 0)
	{
		#$json .= qq(  ${table}: [\n);
		$json .= qq(${table} = [\n);
		while (my $record_HR = $sth->fetchrow_hashref)
		{
			$json .= "\t{\n";
			foreach my $field (@{$field_map{$table}})
			{
				$json .= qq(\t  '$field': '$record_HR->{$field}',\n);
			}
			$json .= "\t},\n";
		}
		$json .= "]\n";
	}
	return $json;
}

=head3 Verify a Date Field

Validate a date field using a supplied Unix Date specification. Set a scalar reference if test fails.

=cut

sub format_date
{
    my ($self, $val, $date_spec);
    ($self, $val, $date_spec) = @_;
    
    return &UnixDate($val, $date_spec);
}

__DATA__
package inven_db;

use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';

use Date::Manip;
&Date_Init("TZ=CST");

use LWP;

use Win32::ODBC;

my($connect_string, $itam_connect_string, %users, $cookie_path, %common_template);

# command to update docs
# cd C:\Documents and Settings\e113676\My Documents\xampp-win-1.7.3\xampp\cgi-bin\inventory
# pod2html.bat --htmlroot=docs --infile=inven_db.pm --outfile=docs\inven_db.html


=head1 Inventory System Perl Module

This is the main Perl library for the inventory system.

=cut

=head2 Production or Development

Use this section to set the correct parameters for the Production or the Development servers. 
Use 1 for production, 0 for development.
	
=cut

if(1)
{
    $connect_string = "DSN=InventoryDB;UID=updater;PWD=tipleh7;";
    $cookie_path = '/inventory/';
}
else
{
    $connect_string = "DSN=HPL-Inven_dev_db;UID=dev_inven;PWD=bobWhite;";
    $cookie_path = '/cgi-bin/inventory/';
}

$itam_connect_string = "DSN=HPL-ITAM-W;UID=updater;PWD=tipleh7;";

=head2 Web Server Section

Elements in this section are mainly used to generate the html
used in the web-application side of things.

=head3 HTML Templates

These are short bits of HTML code to use for listings and things.

=cut

%common_template = (
    widset_1 => qq(<div class="widset_1"><div class="label">%s</div><div class="widget">%s</div><div class="err">%s</div></div>\n),
    widset_1a => qq(<div class="widset_1a"><div class="label">%s</div><div class="widget">%s</div><div class="err">%s</div></div>\n),
    widset_2 => qq(<div class="widset_2"><div class="label">%s</div><div class="widget">%s</div><div class="err">%s</div></div>\n),
    info_1 => qq(<div class="info_1"><div class="heading">%s</div><div class="body">%s</div></div>\n),
    table_2 => qq(<tr><td><b>%s</b></td><td>%s</td></tr>\n),
    table_2_2 => qq(<tr><td><b>%s</b></td><td>%s</td><td><b>%s</b></td><td>%s</td></tr>\n),
);

$common_template{'widset_1a_g2'} =
qq( <div class="widset_group">
$common_template{'widset_1a'}
$common_template{'widset_1a'}
    </div>\n);


=head3 New object for Web Application

This sets up a Perl object for webserver use.

	use strict;
	use inven_db;
	my ($inven_db);
	$inven_db = new inven_db;

Might set up another constructor for non-web use.
=cut

sub new
{
    my ($class, $self);
    $class = shift;
    $self = {};
    bless $self, $class;
    $self->{'CGI'} = new CGI;
    $self->{'common_template'} = \%common_template;
    return $self;
}

=head3 DB Quick Query

This method will create a connection to the inventory database and run a provided
query. It will return a database object to use as needed.

	$db_object = $inven_db->db_select_query(<inventory database query>);

=cut

sub db_select_query # get database handle using supplied query
{
    my ($self, $query, $db_obj);
    ($self, $query) = @_;
    $db_obj = new Win32::ODBC($connect_string)
      or die "Error: " . Win32::ODBC::Error() . "\n";
    if($db_obj->Sql($query))
    {
        die "\nError: " . Win32::ODBC::Error() . "\n";
    }
    return $db_obj;
}

=head3 ITAM Quick Query

This method will create a connection to the ITAM database ans run a provided
query. It will return a database object to use as needed. The ITAM database 
was the previous version of the inventory system. There is no reason to use it 
now.

	$db_object = $inven_db->itam_db_select_query(<inventory ITAM query>);

=cut

sub itam_db_select_query # get database handle using supplied query
{
    my ($self, $query, $db_obj);
    ($self, $query) = @_;
    $db_obj = new Win32::ODBC($itam_connect_string)
      or die "Error: " . Win32::ODBC::Error() . "\n";
    if($db_obj->Sql($query))
    {
        die "\nError: " . Win32::ODBC::Error() . "\n";
    }
    return $db_obj;
}

=head3 Non-data Query

A way to run a query that does not return data.

	$inven_db->db_do(<inventory ITAM query>);

=cut

sub db_do # run query
{
    my ($self, $query, $db_obj);
    ($self, $query) = @_;
    $db_obj = new Win32::ODBC($connect_string)
      or die "Error: " . Win32::ODBC::Error() . "\n";
    if($db_obj->Sql($query))
    {
        die "\nError: " . Win32::ODBC::Error() . "\n";
    }
    return 1;
}

=head3 Next Record

Get the next record from an existing db object. The record is returned as a hash reference.

	$record_HR = $inven_db->db_do(<database object>);

=cut

sub db_fetchrow_hashref # get next record from database handle
{
    my ($self, $db_obj);
    ($self, $db_obj) = @_;
    if($db_obj->FetchRow())
    {
        my %record = $db_obj->DataHash();
        return \%record;
    }
    else
    {
        $db_obj->Close;
        return undef;
    }
}

=head3 Escape Value

Remove unwanted characters from a supplied value.

	$escaped_val = $inven_db->escape_val($val);
	
This needs work. It should detect more characters and maybe substitute for others. (' => '')

=cut

sub escape_val
{
    my ($self, $value, @vals);
    ($self, $value) = @_;
    @vals = $value =~ /([^&]+)/g;
    return join('45', @vals);
}

=head3 Quote 

Return a value quoted for use in a query.

	$quoted_val = $inven_db->db_quote($val);
	
Should this call escape_val?

=cut

sub db_quote
{
    my ($self, $value, $return_value);
    ($self, $value) = @_;
    $return_value = qq('$value');
    return $return_value;
}
=head3 Get Log-in/Log-out Link

Get link based on user status.

=cut

sub get_user_link
{
    my ($self, $username);
    $self = shift;
    $username = $self->{'auth'}{'tech_name'};
    if ($username =~ /\S/)
    {
        return qq(<a href="$self->{'CGI'}->{'SCRIPT_NAME'}?logout=1">logout $username</a>);
    }
    else
    {
        return qq($username <a href="$self->{'CGI'}->{'SCRIPT_NAME'}?login=1">login</a>);
    }
}

=head3 Authorize

Manage how users interact with the system. Verifies who someone is and what they can do.
Uses cookies to maintain state.

=cut

sub auth
{
    my($self, $username, $password);
    ($self) = @_;
    #find username
    if($self->{'logout'})
    {
        return undef;# might put a redirect here, push users back to main
    }
    elsif($username = $self->{'CGI'}->cookie('USER'))
    {
        $self->_get_privileges($username);
        if($username eq $self->{'auth'}{'tech_name'})
        {
            return 1;
        }
    }
    elsif(($username = $self->{'CGI'}->param('username')) && ($password = $self->{'CGI'}->param('password')))
    {
        my($pass_crypt);
        $pass_crypt = $self->passwd($password);
        $self->_get_privileges($username);
        #if($username eq $self->{'auth'}{'tech_name'} && $password eq $self->{'auth'}{'tech_passwd'})
        #print "$password $pass_crypt eq $self->{'auth'}{'tech_passwd'}\n";
        if($pass_crypt eq $self->{'auth'}{'tech_passwd'})
        {
            #print "1\n";
            $self->{'COOKIE'} = $self->{'CGI'}->cookie(
                  -name=>'USER',
                  -value=>$username,
                  -expires=>'+9h',
                  -path=>$cookie_path);
            return 1;
        }
        elsif($self->https_auth($username, $password))
        {
            #print "2\n";
            $self->{'COOKIE'} = $self->{'CGI'}->cookie(
                  -name=>'USER',
                  -value=>$username,
                  -expires=>'+9h',
                  -path=>$cookie_path);
            return 1;
        }
    }
    $self->{'auth'} = undef;
    return "failed";#undef;
    #if(0)#else
    #{
    #    return undef
    #}
}

=head3 Logout

Log out of the system.

=cut

sub logout
{
    my($self);
    $self = shift;
    $self->{'logout'}++;
    $self->{'auth'} = {};
    $self->{'COOKIE'} = $self->{'CGI'}->cookie(
                  -name=>'USER',
                  -value=>'',
                  -path=>$cookie_path);
}

=head3 Get Username

Return the name of current user.

=cut

sub get_user_name
{
    my($self);
    $self = shift;
    return $self->{'auth'}{'tech_name'};
}

=head3 Get User ID

Return the ID number of current user.

=cut

sub get_user_id
{
    my($self);
    $self = shift;
    return $self->{'auth'}{'tech_key'};
}

=head3 Get User Privileges

Return the Privileges of current user.

=cut

sub _get_privileges
{
    my($self, $username, $query, $db_obj);
    ($self, $username) = @_;
    $username = $self->db_quote($username);
    $query = "select tech_name, tech_key, tech_passwd, tech_pr1, tech_pr2, tech_pr3, tech_pr4, tech_pr5
           from tech where tech_name = $username;";      
    $db_obj = $self->db_select_query($query);
    $self->{'auth'} = $self->db_fetchrow_hashref($db_obj);
}

=head3 Get Permission

Return permission to do a specific action.

=cut

sub get_permission
{
    my($self, $level, $l_label);
    ($self, $level) = @_;
    $l_label = "tech_pr${level}";
    return $self->{'auth'}{$l_label};
}

=head3 Password

Return hashed value for a clear-text password..

=cut

sub passwd
{
    my($self, $passwd);
    ($self, $passwd) = @_;
    #return crypt('s', $passwd);
    return crypt($passwd, substr($passwd, 0, 1));
}

=head3 Get Tech Key

Repeat of get user ID.

=cut

sub get_tech_key
{
    my($self, $dbo, $record_HR);
    $self = shift;
    return $self->get_user_id();
}

=head3 Authenticate

Contact Intranet server for user login.

=cut

sub https_auth
{
    my($self, $user, $passwd, $req, $ua, $body);
    ($self, $user, $passwd) = @_;
    $ua = LWP::UserAgent->new;
    #$req = HTTP::Request->new(GET => 'https://hplnet.hpl.lib.tx.us/cgi-bin/api/verify.pl');
    $req = HTTP::Request->new(GET => 'https://hplnet.houstonlibrary.org/cgi-bin/api/verify.pl');
    $req->authorization_basic($user, $passwd);
    $body = $ua->request($req)->as_string;
    if($body =~ /\|\|GTG\|\|/)
    {
        return(1);
    }
    else
    {
        return(0);
    }
}

=head3 Login Form

Generate a login form.

=cut

sub login_form
{
    my($self, $form);
    $self = shift;
    $form .= $self->{'CGI'}->start_form('POST', $ENV{'SCRIPT_NAME'});
    $form .= $self->{'CGI'}->hidden('reffer', $ENV{'HTTP_REFERER'});
    $self->{'CGI'}->param('stage', 'login');
    $form .= $self->{'CGI'}->hidden('stage');
    $form .= "Username: " . $self->{'CGI'}->textfield('username', '', 12) . "<br>\n";
    $form .= "Password: " . $self->{'CGI'}->password_field('password', '', 12) . "<br>\n";
    $form .= $self->{'CGI'}->submit('Login');
    $form .= $self->{'CGI'}->end_form;
    return $form;
}

=head3 Get Template

Get a page template from the filesystem. This will recursivly load sub-templates.

=cut

sub get_template
{
    my($self, $template, $FH, $page);
    ($self, $template) = @_;
    open($FH, '<', $template);
    while(my $line = <$FH>)
    {
        $page .= $line;
    }
    $page =~ s/\[\{([^\}]+)\}\]/$self->get_template($1)/eg;
    return $page;
}

=head3 Send Page

Given a template name and page data as a hashref, print a page.

=cut

sub send_page
{
    my($self, $template, $data_HR, $FH, $page);
    ($self, $template, $data_HR) = @_;

    $page = $self->get_template($template);
    
    $page =~ s/\[\[\$([^\]]+)\]\]/$data_HR->{$1}/g;
    if(exists $self->{'COOKIE'})
    {
        print $self->{'CGI'}->header(-cookie=>$self->{'COOKIE'});
    }
    else
    {
        print $self->{'CGI'}->header;
    }
    print $page;
}

=head3 Get Menu List

Return a sorted arrayref for use in a CGI menu.

Include option to add a leading space 

=cut

sub get_menu_list
{
    my($self, $type, $null_option, $db_obj, $query, %data, %exclusions, @list);
    ($self, $type, $null_option) = @_;
	%exclusions =
	(
		'status_type' =>
		{
			'(d)Reference' => 1,
			'(d)Repair' => 1,
			'(d)Reusable' => 1,
			'(d)Staff' => 1,
			'(d)Stolen' => 1,
			'(d)Storage' => 1,
			'(d)Unknown' => 1,
			'(d)Working' => 1,
			'(d)Loaner' => 1,
			'(d)Not on Site' => 1,
			'(d)Prep' => 1,
			'New' => 1,
		},
		'e_use_type' =>
		{
			'(d)IT Tech' => 1,
			'(d)Public' => 1,
			'(d)Ref' => 1,
			'(d)Salvage' => 1,
			'(d)Staff' => 1,
			'Unknown' => 1,
		}
	);
	if($type eq 'status_type')
	{
		
		$query = "select * from status_type";    
		$db_obj = $self->db_select_query($query);
		#print "\n$query\n";
		while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
		{
			next if(exists $exclusions{$type}->{$record_HR->{'status_type_name'}});
			$data{$record_HR->{'status_type_key'}} = $record_HR->{'status_type_name'};
		}
		
		@list = sort {$data{$a} cmp $data{$b}} keys %data;
		#return \%data
	}
	if($type eq 'e_use_type')
	{
		
		$query = "select * from e_use_type";    
		$db_obj = $self->db_select_query($query);
		#print "\n$query\n";
		while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
		{
			next if(exists $exclusions{$type}->{$record_HR->{'e_use_type_name'}});
			$data{$record_HR->{'e_use_type_key'}} = $record_HR->{'e_use_type_name'};
		}
		
		@list = sort {$data{$a} cmp $data{$b}} keys %data;
		#return \%data
	}
	#push(@list, 'do', 're', 'mi');
	#print join(', ', @list), "<br>\n";
	if($null_option)
	{
		unshift(@list, '');
		return \@list;
	}
	else
	{
		return \@list;
	}
}

=head3 Get Manufacturers

Return a hashref of all the manufacturers listed in the system.

=cut

=head4 Possible Enhancement

Change these methods to accept a parameter or a routine to limit the returned values. 

=cut

sub get_manufacturer
{
    my($self, $db_obj, $query, %data, $manufacturer_HR, $equipment_type_HR);
    $self = shift;
    $query = "select * from manufacturer";    
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'manufacturer_key'}} = $record_HR->{'manufacturer_name'};
    }
    return \%data
}

=head3 Get Equipment Types

Return a hashref of all the equipment types listed in the system.

=cut

sub get_equipment_type
{
    my($self, $db_obj, $query, %data);
    $self = shift;
    $query = "select * from equipment_type";    
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'equipment_type_key'}} = $record_HR->{'equipment_type_name'};
    }
    return \%data
}

=head3 Get Status Types

Return a hashref of all the status types listed in the system.

=cut

sub get_status_type
{
    my($self, $db_obj, $query, %data);
    $self = shift;
    $query = "select * from status_type";    
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'status_type_key'}} = $record_HR->{'status_type_name'};
    }
    return \%data
}

=head3 Get Buildings

Return a hashref of all the buildings listed in the system.

=cut

sub get_building
{
    my($self, $db_obj, $query, %data);
    $self = shift;
    $query = "select * from building";    
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'building_key'}} = $record_HR->{'building_name'};
    }
    return \%data
}

=head3 Get Rooms

Return a hashref of all the rooms listed in the system. Accepts an optional parameter to return only
rooms that are used in the location table.

=cut

sub get_room
{
    my($self, $db_obj, $query, %data, $only_used);
    ($self, $only_used) = @_;
    if($only_used)
    {
        $query = "SELECT r.room_key, r.room_name, r.building_key, b.building_name
            FROM room r
            JOIN building b ON r.building_key = b.building_key
            where r.room_key in (select distinct room_key from location)";
        $db_obj = $self->db_select_query($query);
    }
    else
    {
        $query = "SELECT r.room_key, r.room_name, r.building_key, b.building_name
            FROM room r
            JOIN building b ON r.building_key = b.building_key";
        $db_obj = $self->db_select_query($query);
    }
    

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        if($record_HR->{'room_name'} =~ /\S/)
        {
	        next if($record_HR->{'room_name'} =~ /\A\(d\)/);#GME 2014-01-17
            $data{$record_HR->{'room_key'}} = "$record_HR->{'building_name'} - $record_HR->{'room_name'}";
        }
        else
        {
            $data{$record_HR->{'room_key'}} = $record_HR->{'building_name'};
        }
    }
    return \%data
}

=head3 Get Models

Return a hashref of all the models listed in the system. Accepts two optional parameters. The first chooses
either a consise(label only) or verbose(anon array of values) set of return values. The second returns only
items that are used in the equipment table.

=cut

sub get_model
{
    my($self, $db_obj, $query, %data, $return_type, $only_used);
    ($self, $return_type, $only_used) = @_; # only used flag limits models to those found in equipment
    if($only_used)
    {
        $query = "select m.model_key, et.equipment_type_name, m.model_name, m.model_number, ma.manufacturer_name from
            model m
            join equipment_type et on m.equipment_type_key = et.equipment_type_key
            join manufacturer ma on m.manufacturer_key = ma.manufacturer_key
            where model_key in (select distinct model_key from equipment);";
    }
    else
    {
        $query = "select m.model_key, et.equipment_type_name, m.model_name, m.model_number, ma.manufacturer_name from
            model m
            join equipment_type et on m.equipment_type_key = et.equipment_type_key
            join manufacturer ma on m.manufacturer_key = ma.manufacturer_key;";
    }
    $db_obj = $self->db_select_query($query);

    if($return_type == 1)
    {
        #returns hash of anon arrays 
        while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
        {
            $data{$record_HR->{'model_key'}} = [$record_HR->{'equipment_type_name'}, $record_HR->{'manufacturer_name'}, $record_HR->{'model_name'}, $record_HR->{'model_number'}];
        }
    }
    else
    {
        #returns hash of labels
        while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
        {
            #$data{$record_HR->{'model_key'}} = "$record_HR->{'equipment_type_name'}, $record_HR->{'manufacturer_name'}, $record_HR->{'model_name'}";
			$data{$record_HR->{'model_key'}} = sprintf("%s, %s, %s(%s)",
				$record_HR->{'equipment_type_name'}, $record_HR->{'manufacturer_name'}, $record_HR->{'model_name'}, $record_HR->{'model_number'});
        }
    }
    return \%data
}

=head3 Get Unused Gtags

Return a hashref of all the Gtags listed in the gtag table that are not listed in the equipment table.

=cut

sub get_unused_gtags
{
    my($self, $db_obj, $query, %data);
    $self = shift;
    $query = "SELECT gtag_key, gtag_num
        FROM gtag
        WHERE gtag_key NOT IN (SELECT gtag_key FROM equipment WHERE gtag_key IS NOT NULL)";
        
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'gtag_key'}} = $record_HR->{'gtag_num'};
    }
    return \%data
}

=head3 Get POs

Return a hashref of all the POs.

=cut

sub get_po
{
    my($self, $db_obj, $query, %data);
    $self = shift;
    $query = "SELECT po_key, po_number FROM po";
        
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'po_key'}} = $record_HR->{'po_number'};
    }
    return \%data
}
sub get_e_use_type
{
    my($self, $db_obj, $query, %data);
    $self = shift;
    $query = "SELECT e_use_type_key, e_use_type_name FROM e_use_type";
        
    $db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
        $data{$record_HR->{'e_use_type_key'}} = $record_HR->{'e_use_type_name'};
    }
    return \%data
}

=head3 Verify a Text Field

Validate a text field using a supplied regex. Set a scalar reference if test fails.

=cut

sub valid_text_field
{
    my ($self, $var, $error_SR, $test_regex, $val);
    ($self, $var, $error_SR, $test_regex) = @_;
    
    $val = $self->escape_val($self->{'CGI'}->param($var));

    if(length($val) < 1)
    {
        ${$error_SR} = 1;
        return $val;
    }
    if($test_regex =~ /\S/)
    {
        unless($val =~ /$test_regex/)
        {
            ${$error_SR} = 1;
            return undef;
        }
    }
    return $val;
}

=head3 Verify a Date Field

Validate a date field using a supplied Unix Date specification. Set a scalar reference if test fails.

=cut

sub valid_date_field
{
    my ($self, $var, $error_SR, $date_spec, $val);
    ($self, $var, $error_SR, $date_spec) = @_;
    
    $val = &ParseDate($self->escape_val($self->{'CGI'}->param($var)));

    if(length($val) < 1)
    {
        ${$error_SR} = 1;
        return $val;
    }
    if($date_spec =~ /\S/)
    {
        unless($val = &UnixDate($val, $date_spec))
        {
            ${$error_SR} = 1;
            return undef;
        }
    }
    return $val;
}
=head3 Location Mapping

Get a HashRef keyed by equipment_key containing an ArrayRef[building_name, room_name, assigned_to]

=cut
sub get_location_map
{
	my($self, $db_obj, $query, %room_map, %location_map);
	$self = shift;
	
	$query = "select r.room_key, r.room_name, b.building_name
		from room r
		join building b on r.building_key = b.building_key";

	$db_obj = $self->db_select_query($query);

    while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
    {
		$room_map{$record_HR->{'room_key'}} = [$record_HR->{'building_name'}, $record_HR->{'room_name'}];
    }

	$query = "select * from location order by location_key asc";
	$db_obj = $self->db_select_query($query);
	while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
	{
		$location_map{$record_HR->{'equipment_key'}} = [@{$room_map{$record_HR->{'room_key'}}}, $record_HR->{'assigned_to'}];
	}
	return \%location_map;
}
=head3 Status Mapping

Get a HashRef keyed by equipment_key containing an ArrayRef[status_type_name, status_date]

=cut
sub get_status_map
{
	my($self, $db_obj, $query, %type_map, %status_map);
	$self = shift;
	
	$query = "select * from status_type";
	$db_obj = $self->db_select_query($query);
	while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
	{
		$type_map{$record_HR->{'status_type_key'}} = $record_HR->{'status_type_name'};
	}
	
	$query = "select * from e_status order by status_key asc";
	$db_obj = $self->db_select_query($query);
	while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
	{
		$status_map{$record_HR->{'equipment_key'}} = [$type_map{$record_HR->{'status_type_key'}}, $record_HR->{'status_date'}];
	}
	return \%status_map;
}
=head3 Use Mapping

Get a HashRef keyed by equipment_key containing an ArrayRef[status_type_name, e_use_date]

=cut
sub get_use_map
{
	my($self, $db_obj, $query, %type_map, %use_map);
	$self = shift;
	
	$query = "select * from e_use_type";
	$db_obj = $self->db_select_query($query);
	while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
	{
		$type_map{$record_HR->{'e_use_type_key'}} = $record_HR->{'e_use_type_name'};
	}
	$query = "select * from e_use order by e_use_key asc";
	$db_obj = $self->db_select_query($query);
	while(my $record_HR = $self->db_fetchrow_hashref($db_obj))
	{
		my (%row);
		%row = $db_obj->DataHash();
		$use_map{$record_HR->{'equipment_key'}} = [$type_map{$record_HR->{'e_use_type_key'}}, $record_HR->{'e_use_date'}];
	}
	return \%use_map;
}
1;

