#!/usr/bin/perl
#
# 'Sourcedid.source','Sourcedid.Id','Parent Course','Section Title','Start Date','End Date','Student Last Access','Non-Student Last Access','Instructors','Designers'
# 'Amaint','1104-hum-130-c200','HUM130','C200 Summer10 Introduction to Religious Studies','11-MAY-10','29-AUG-10','28-AUG-10','25-MAY-11','cdeadmin|cjones2','cdeadmin'
# 'Amaint','1104-engl-455w-d100','ENGL455w','D100 Summer10 Topics in Canadian Literature','04-MAY-10','07-SEP-11','10-MAY-11','30-JUL-10','gerson','gerson'
# 'Amaint','1104-sa-150-d100','SA150','D100 Summer10 Introduction to Sociology  (S )','11-MAY-10','01-SEP-10','31-AUG-10','20-AUG-10','otero','otero|kpp'
# 'Amaint','1104-kin-806-g100','KIN806','G100 Summer10 Special Topics','11-MAY-10','07-SEP-10','15-AUG-10','08-JUL-10','mchapple','mchapple'
# 'Amaint','1104-ling-110-d100','LING110','D100 Summer10 The Wonder of Words','11-MAY-10','07-SEP-10','07-SEP-10','20-OCT-10','ypankrat','ypankrat'
# 'Amaint','1104-iat-100-d110','IAT100','D110 Summer10 Systems of Media Representation','11-MAY-10','07-SEP-10','07-SEP-10','12-AUG-10','vmoulder|sclement','vmoulder|sclement'
# 'Amaint','1104-psyc-280-d100','PSYC280','D100 Summer10 Introduction to Biological Psychology','11-MAY-10','07-SEP-10','07-SEP-10','22-MAR-11','nwatson','szilioli|nwatson'
# 'Amaint','1104-math-254-d100','MATH254','D100 Summer10 Vector and Complex Analysis for Applied Sciences','11-MAY-10','07-SEP-10','07-SEP-10','08-AUG-11','rwwitten','bquaife|rwwitten|mlysne'
# 'Amaint','1104-educ-471-e400','EDUC471','E400 Summer10 Curriculum Development: Theory and Practice','11-MAY-10','07-SEP-10','07-SEP-10','17-MAY-11','nataliag','nataliag'

use lib '/opt/amaint/etc/lib';
use awsomeLinux;
use Text::CSV::Encoded;

$csv = Text::CSV::Encoded->new ({ encoding => "iso-8859-1" });
$csvout = Text::CSV::Encoded->new ({ encoding => "utf8" });

$file = shift;

$out = STDOUT;

# Initialize the SOAP service (needed to fetch SFUIDs from Amaint)
getService();


#print "course_id,short_name,long_name,account_id,term_id,status";
$csvout->print ($out,["course_id","user_id","role","section_id","status"]);
print "\n";

open ($io, $file) or die "Can't open $file";

$count = 0;

while ($row = $csv->getline($io))
{
	$count++;
	next if ($count == 1);

	@fields = @$row;

	$sis_id = $fields[1];
	$teach = $fields[8];
	$des = $fields[9];

	# Strip leading and trailing quotes - CSV module adds them anyway
	$teach =~ s/^'//;
	$teach =~ s/'$//;
	$des =~ s/^'//;
	$des =~ s/'$//;
	$sis_id =~ s/^'//;
	$sis_id =~ s/'$//;

	@teachers = split(/\|/,$teach);
	@designers = split(/\|/,$des);

	foreach $t (@teachers)
	{
	    print STDERR "processing $t in $sis_id\n";
	    $sfuid = getID($t);
	    if (!$sfuid)
	    {
		print "WARNING: Skipping $t for $sis_id - SFUID not found in Amaint\n";
		next;
	    }
	    $csvout->print ($out,[$sis_id,$sfuid,"teacher","","active"]);
	    print "\n";
	}

	foreach $t (@designers)
	{
	    $sfuid = getID($t);
	    if (!$sfuid)
	    {
		print "WARNING: Skipping $t for $sis_id - SFUID not found in Amaint\n";
		next;
	    }
	    $csvout->print ($out,[$sis_id,$sfuid,"designer","","active"]);
	    print "\n";
	}
}


sub getID
{
	my $user = shift;
	if (!defined($sfuids{$user}))
	{
	    my ($roles,$sfuid,$lastname,$firstnames,$givenname) = split(/:::/,infoForComputingID($user));
            if ($roles !~ /[a-z]+/)
            {
                # print STDERR "Got back invalid response from infoForComputingID for $user. Skipping add\n";
		return 0;
            } 
	    $sfuids{$user} = $sfuid;
	    return $sfuid;
	}
	else
	{
	    return $sfuids{$user};
	}
}
