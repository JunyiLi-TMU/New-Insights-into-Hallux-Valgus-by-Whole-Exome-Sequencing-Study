my $maf=0.01;
while(<>){
                if ( !/gnomAD_exome_EAS=[0-9]/ ) {
                print ;
                next ;
                }
                if ( /gnomAD_exome_EAS=(0\.[0-9]+);/ ) {
                print if $1 < $maf;
                next;
                }
}