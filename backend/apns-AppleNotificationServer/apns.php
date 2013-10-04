<?php
$deviceToken="bf6b22f9 f9e42d17 3ecb8ee7 42ee18d9 2726575b 2180aa90 340b6b01 89108276";
$payload['aps'] = array('alert' => 'Your Dad asks you to update your location');
$output = json_encode($payload);

#
# development environment
#
#$apnsHost = 'gateway.sandbox.push.apple.com';
#$apnsCert = 'apns-dev-cert-bundle.pem';

#
# production environment
#
$apnsHost = 'gateway.push.apple.com';
$apnsCert = 'apns-prod-cert-bundle.pem';

$apnsPort = 2195;
$streamContext = stream_context_create();
stream_context_set_option($streamContext, 'ssl', 'local_cert', $apnsCert);
$apns = stream_socket_client('ssl://' . $apnsHost . ':' . $apnsPort, $error, $errorString, 2, STREAM_CLIENT_CONNECT, $streamContext);
print $errorString;
$apnsMessage = chr(0) . chr(0) . chr(32) . pack('H*', str_replace(' ', '', $deviceToken)) . chr(0) . chr(strlen($output)) . $output;
fwrite($apns, $apnsMessage);
fclose($apns);
?>
