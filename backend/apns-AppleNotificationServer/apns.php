<?php
$deviceToken="9d9ed2f7 60780c69 1a4727e6 d428cbe7 7fd84bad 9ab16206 5afd8f4c f12feab3";
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

