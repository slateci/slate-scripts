source 00-set-cluster-id.rc

mkdir -p -m 0700 "$HOME/.slate"
if [ "$?" -ne 0 ] ; then
	echo "Not able to create $HOME/.slate" 1>&2
	exit 1
fi

echo $SLATE_TOKEN > "$HOME/.slate/token"
if [ "$?" -ne 0 ] ; then
	echo "Not able to write token data to $HOME/.slate/token" 1>&2
	exit 1
fi
chmod 600 "$HOME/.slate/token"
echo 'https://api.slateci.io:18080' > ~/.slate/endpoint

echo "SLATE access token successfully stored"
