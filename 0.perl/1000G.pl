my $maf=0.01;
while(<>){
                if ( !/1000g2015aug_eas=[0-9]/ ) {
                print ;
                next ;
                }
                if ( /1000g2015aug_eas=(0\.[0-9]+);/ ) {
                print if $1 < $maf;
                next;
                }
}