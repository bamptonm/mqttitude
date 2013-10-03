<?php
$deviceToken="769df01c e391d91b 1fc6bbb7 c16b533f d8ae80f1 1f453628 bbcb57b0 1aa9c31f";
$payload['aps'] = array('alert' => 'Your Dad asks you to update your location');
$output = json_encode($payload);
$apnsHost = 'gateway.sandbox.push.apple.com';
$apnsPort = 2195;
$apnsCert = 'apns-dev-cert-bundle.pem';
$streamContext = stream_context_create();
stream_context_set_option($streamContext, 'ssl', 'local_cert', $apnsCert);
$apns = stream_socket_client('ssl://' . $apnsHost . ':' . $apnsPort, $error, $errorString, 2, STREAM_CLIENT_CONNECT, $streamContext);
print $errorString;
$apnsMessage = chr(0) . chr(0) . chr(32) . pack('H*', str_replace(' ', '', $deviceToken)) . chr(0) . chr(strlen($output)) . $output;
fwrite($apns, $apnsMessage);
fclose($apns);
?>
