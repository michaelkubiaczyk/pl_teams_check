open (IN, "teams.csv");

my $line = <IN>;

my %teams;
my %errors;

while ( $line = <IN> ) {
    my ( $teamid, $teamname, $teampath ) = split /,/, $line, 3;
    
    addTeam( $teamid, $teamname, $teampath );
}

close IN;


print "Checking teams...\n";

#while ( ($key, $value) = each (%teams) ) {
foreach my $key ( sort keys %teams ) {
#    print "Checking $key - ". niceTeam($key) .", path: ". $teams{$key}{path} ."\n";
    checkPath( $key, $teams{$key}{path} );
}


#while ( ($key, $value) = each (%errors) ) {
foreach my $key ( sort {niceTeam($a) cmp niceTeam($b)} keys %errors ) {
    my $value = $errors{$key};
    if ( $value->{bad} > 0 ) {
        print "There is an error with " . niceTeam($key) .": ". $value->{good} ." correct & ". $value->{bad} ." bad children\n";
        my $teamPath = $teams{$key}{path} . $key;
        print "\tCurrent path: \n\t\t". nicePath( $teamPath ) ."\n";
        print "\tMisplaced children: \n";        
        my @tlist = sort { niceTeam($a) cmp niceTeam($b) } @{$value->{children}{bad}};
        foreach my $team ( @tlist ) {
            my $childPath = $teams{$team}{path} . $team;
            print "\t\t". nicePath( $childPath ) ."\n";
        }
        
        print "\tValid children: \n";        
        my @tlist = sort { niceTeam($a) cmp niceTeam($b) } @{$value->{children}{good}};
        foreach my $team ( @tlist ) {
            my $childPath = $teams{$team}{path} . $team;
            print "\t\t". nicePath( $childPath ) ."\n";
        }
    }
}

open (OUT, ">teams-aug.csv");
print OUT "sep=;\n";
print OUT "TeamID; TeamName; TeamPath; TeamPath Augmented;Valid Path;\n";
while ( ($key, $value) = each (%teams) ) {
    my %arr = %{$value};
    print OUT "$key; ". $arr{name} .";". $arr{path} .";". nicePath($arr{path}) .";". $arr{valid} ."\n";
}
close OUT;


sub addTeam {
    my ( $teamid, $teamname, $teampath ) = (shift, shift, shift);
    $teampath =~ s/[,\n]//g;
    $teams{$teamid}{name} = $teamname;
    $teams{$teamid}{path} = $teampath;
}

sub checkPath {
    my ($team, $path ) = (shift,shift);
    
    if ( $path =~ /^(.*\\)([^\\]+)/ ) {
        my $parent = $2;
        my $parentPath = "\\";
        if ( $parent ne "" ) {
            $parentPath = $teams{$parent}{path} . $parent . "\\";
        }
        # $team lives at path $path\\$team
        # $parent lives at $parentPath\\$parent
        # $team should live at $parentPath\\$parent\\$team
        
        my $actualPath = $path.$team;
        my $calculatedPath = $parentPath . $team;

        if ( !defined( $errors{$parent} ) ) {
            $errors{$parent}{children}{bad} = ();
            $errors{$parent}{children}{good} = ();
            $errors{$parent}{good} = 0;
            $errors{$parent}{bad} = 0;                
        }
        
        #print "Path is: $path. \nActual: $actualPath. \nCalculated: $calculatedPath\n";
        
        #if ( $teams{$parent}{path} ne $parentPath ) {
        if ( $actualPath ne $calculatedPath ) { 
 #           print "Error in path for team ". niceTeam($team) .":\n";
            print "Error in ".$teams{$team}{name} ."'s path: " . nicePath($path) ."? \n\t => Parent (". niceTeam($parent) .") is actually at: ". nicePath($parentPath) ."\n";
            
            #print "Team ". niceTeam( $team ) ." thinks it lives at: ". nicePath( $path ) ."\n\t but parent ". niceTeam($parent) ." lives at ". nicePath( $parentPath ) ."\n";
 #           print "  1. ". niceTeam( $team ). " path: ". nicePath($actualPath) ."\n";
 #           print "  2. Parent ". niceTeam( $parent ) ." path: ". nicePath($parentPath) ."\n";
 #           print "  => Correct path: ". nicePath( $calculatedPath ) ."\n";
            #comparePaths( $path, $calculatedPath );
            $teams{$team}{valid} = 0;            
            push @{$errors{$parent}{children}{bad}}, $team;
            $errors{$parent}{bad}++;
        } else {
            $teams{$team}{valid} = 1;
            push @{$errors{$parent}{children}{good}}, $team;
            $errors{$parent}{good}++;
        }
    }
}


sub comparePaths {
    my ( $p1, $p2 ) = (shift, shift);
    
    my @a1 = split /\\/, $p1;
    my @a2 = split /\\/, $p2;
    
    my $c = 1;
    
    while ( defined($a1[$c]) || defined($a2[$c]) ) {
        #print "[$c] - ". niceTeam($a1[$c]) ." vs ". niceTeam($a2[$c]) ."\n";
        
        if ( $a1[$c] eq $a2[$c] ) {
            print niceTeam($a1[$c]) . "\\";
        } else {
            print "\n\tError: ". niceTeam($a1[$c]) ." vs ". niceTeam($a2[$c]) ."\n";
        }
        $c++;
    }
}

sub niceTeam {
    my $team = shift;
    if ( !defined( $teams{$team} ) || !defined( $teams{$team}{name} ) ) {
        print "Error trying to make $team team nice.\n";
        exit;
    }
    return $teams{$team}{name} ." (". substr( $team, 0, 4 ) .")";
}

sub nicePath {
    my $teamPath = shift;
    my @path = split /\\/, $teamPath;
    
    my $ret = "";
    for ( my $c = 1; $c < scalar(@path); $c++ ) {
    #    print $path[$c];
        $ret .= "\\" . niceTeam( $path[$c] );
    }
    
    #print "nicePath for $teamPath returning $ret\n";
    
    return $ret;
}