FNR==NR{
a[$1]=$2
b[$1]=$3
c[$1]=$4
d[$1]=$5
  next
}
{ if ($1 in a) {print a[$1]"\t"b[$1]"\t"c[$1]"\t"d[$1]} else {print $1, "NA"}  }
