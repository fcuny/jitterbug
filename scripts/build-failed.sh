COMMITER=$1
MESSAGE=$2
OUTPUT=$3
SHA=$4

echo "
Message:
$MESSAGE

$OUTPUT
" | mail -s "[jitterbug] BUILD FAILED $SHA" $COMMITER
