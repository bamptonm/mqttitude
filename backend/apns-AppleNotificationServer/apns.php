<?php
$deviceToken="bd41949a c6f94c34 ab190cb1 93e246be 859cc5d8 488c916f 8d696656 8f1725d6";
$payload['aps'] = array('alert' => 'Your Dad asks you to update your location');
$output = json_encode($payload);
$apnsHost = 'gateway.sandbox.push.apple.com';
$apnsPort = 2195;
$apnsCert = 'apns-dev.pem';
$streamContext = stream_context_create();
stream_context_set_option($streamContext, 'ssl', 'local_cert', $apnsCert);
$apns = stream_socket_client('ssl://' . $apnsHost . ':' . $apnsPort, $error, $errorString, 2, STREAM_CLIENT_CONNECT, $streamContext);
print $errorString;
$apnsMessage = chr(0) . chr(0) . chr(32) . pack('H*', str_replace(' ', '', $deviceToken)) . chr(0) . chr(strlen($output)) . $output;
fwrite($apns, $apnsMessage);
fclose($apns);
?>
