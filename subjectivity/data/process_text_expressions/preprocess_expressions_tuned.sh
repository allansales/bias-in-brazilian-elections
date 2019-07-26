#!/bin/bash
file="$1"
#preprocess_punt="$2"

tmp="tmp.txt"
out_file="$file$tmp"


#if [ "$preprocess_punt" = true ] ; then
#  	cat "$file" | iconv -f utf8 -t ascii//TRANSLIT > $out_file  | tr '[:upper:]' '[:lower:]' | sed -e 's/<[^<>]*>//g' | sed '/[[:punct:]]*/{ s/[^[:alnum:][:space:].]//g}' > $out_file  
#  	cp $out_file $file
#fi

expressions=("a ponto" "ao menos" "ate mesmo" "nao mais que" "nem mesmo" "no minimo" "o unico" "a unica" "pelo menos" "quando menos" "quando muito" "a par disso" "e nao" "em suma" "mas tambem" "muito menos" "nao so" "ou mesmo" "por sinal" "com isso" "como consequencia" "de modo que" "deste modo" "em decorrencia" "nesse sentido" "por causa" "por conseguinte" "por essa razao" "por isso" "sendo assim" "ou entao" "ou mesmo" "como se" "de um lado" "por outro lado" "mais que" "menos que" "nao so" "desde que" "do contrario" "em lugar" "em vez" "no caso" "se acaso" "de certa forma" "desse modo" "em funcao" "isso e" "ja que" "na medida que" "nessa direcao" "no intuito" "no mesmo sentido" "ou seja" "uma vez que" "tanto que" "visto que" "ainda que" "ao contrario" "apesar de" "fora isso" "mesmo que" "nao obstante" "nao fosse isso" "no entanto" "para tanto" "pelo contrario" "por sua vez" "posto que")
#expressions=("quando menos")
for exp in "${expressions[@]}"; do
	echo "$exp"
	sub="${exp// /_}"
    sed -r "s/ $exp/ $sub/g" "$file" > "$out_file"
    cp $out_file $file
done

MYREGEX=\\b\(`perl -pe 's/\n/|/g' stopwords.txt`\)\\b
perl -pe "s/$MYREGEX//g" $file > $out_file
cat $out_file | sed "s/  */ /g" > $file
rm $out_file