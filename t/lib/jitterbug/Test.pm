package jitterbug::Test;
use strict;
use warnings;
use FindBin qw($Bin);

BEGIN{

   warn qq{perl -Ilib $Bin/../scripts/deploy_schema $Bin/data/test.yml}
      unless -r qq{$Bin/data/jitterbug.db};
};
   

1;


