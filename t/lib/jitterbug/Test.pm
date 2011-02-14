package jitterbug::Test;
use strict;
use warnings;
use FindBin qw($Bin);

BEGIN{
   qx{$^X -Ilib $Bin/../scripts/jitterbug_db -c $Bin/data/test.yml --deploy}
      unless -r qq{$Bin/data/jitterbug.db};
};

1;


