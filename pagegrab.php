<?php
	/* 
	 * Script to take post data and return the data with an
	 * appropriate with an appropriate header so a users is prompted
	 * for a download
	 */

        $url = $_GET['url'];
        $mimetype = "application/json";
        if (in_array('mimetype', $_POST)) {
                $mimetype = $_POST['mimetype'];
        }

        // Set headers
        header("Cache-Control: public");
        //header("Content-Description: File Transfer");
        //header("Content-Disposition: attachment; filename=$filename");
        header("Content-Type: " . $mimetype);
        header("Content-Transfer-Encoding: binary");

	// echo file_get_contents($url);
	// file_get_contents is disabled on some servers, so use
	// curl instead.
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $url);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	echo curl_exec($ch);
	curl_close($ch);
?> 
