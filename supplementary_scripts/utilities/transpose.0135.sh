awk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' results/0135_phylogeny_by_fastANI_old/tmp/out.tab > results/0135_phylogeny_by_fastANI_old/tmp/out.t.tab

## 2024-12-02 11:42:50 works for 20K genomes 