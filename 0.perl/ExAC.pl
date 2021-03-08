my $maf=0.01;
while(<>){
                if ( !/ExAC_EAS=[0-9]/ ) {
                print ;
                next ;
                }
                if ( /ExAC_EAS=(0\.[0-9]+);/ ) {
                print if $1 < $maf;
                next;
                }
}