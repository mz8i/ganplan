FILE=$1
START=${2:-0}
TYPES="$3"

N=$( cat $FILE | wc -l )
i=$START

ZOOM=$(head -n 1 $FILE | tr -d '[],' | awk '{print $NF}')

for TYPE in $TYPES; do
    mkdir -p data/tiles/france-ghs-split/$ZOOM/$TYPE/
done

tail -n +$i $FILE | tr -d '[],' | while read col row zoom; do
    i=$(( i + 1 ))
    echo -ne "\r$i/$N: $((100 * $i / $N))% complete"
    for TYPE in $TYPES; do
        wget --quiet localhost:8080/styles/gan-plan-$TYPE/$zoom/$col/$row.png -O data/tiles/france-ghs-split/$zoom/$TYPE/$zoom\_$col\_$row.png
    done
done
