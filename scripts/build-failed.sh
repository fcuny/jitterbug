COMMITER=$1
MESSAGE=$2
OUTPUT=$3
SHA=$4
CC_EMAIL=$5

echo "Message:\n$MESSAGE\nTest Output:\n$OUTPUT\n" | mail -c "$CC_EMAIL" -s "[jitterbug] BUILD FAILED $SHA" $COMMITER
