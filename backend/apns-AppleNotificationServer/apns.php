<?php
$deviceToken="bd41949a c6f94c34 ab190cb1 93e246be 859cc5d8 488c916f 8d696656 8f1725d6";
$payload['aps'] = array('alert' => 'Message sent via APNS');
$output = json_encode($payload);

#
# development environment
#
$apnsHost = 'gateway.sandbox.push.apple.com';
$apnsCert = 'apns-dev-cert-bundle.pem';

#
# production environment
#
#$apnsHost = 'gateway.push.apple.com';
#$apnsCert = 'apns-prod-cert-bundle.pem';

$apnsPort = 2195;
$streamContext = stream_context_create();
stream_context_set_option($streamContext, 'ssl', 'local_cert', $apnsCert);
$apns = stream_socket_client('ssl://' . $apnsHost . ':' . $apnsPort, $error, $errorString, 2, STREAM_CLIENT_CONNECT, $streamContext);
print $errorString;
$apnsMessage = chr(0) . chr(0) . chr(32) . pack('H*', str_replace(' ', '', $deviceToken)) . chr(0) . chr(strlen($output)) . $output;
fwrite($apns, $apnsMessage);
fclose($apns);
?>
