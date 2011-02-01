COMMITER=$1
PROJECT=$2
MESSAGE=$3
OUTPUT=$4
SHA=$5
CC_EMAIL=$6

echo "
Message:
$MESSAGE

Test Output:
$OUTPUT
" | mail -c "$CC_EMAIL" -s "[jitterbug] PASS $PROJECT @ $SHA" $COMMITER
