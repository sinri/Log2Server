<?php

/**
* Log2Server
* ===============
* Demo of Server Side, in PHP
* ---------------
* I. Modify $Log2Server_LogPath as actually expected log directory path;
* Ro. Make sure the log directory is owned by the user of server program user, such as www-data of Apache on Debian;
* Ha. You can rewrite it as you want, as long you keep the rule of the return value, that only two json text are expected to receive by client.
* ---------------
* Copyright 2015 Sinri Edogawa
* Open Source, with GNU GENERAL PUBLIC LICENSE Version 2
*/
class Log2Server
{
	static $Log2Server_LogPath = '/var/log/Log2Server';

	// If you want to integrate it with Flight Framework, use this
	public static function setRoute(){
		Flight::route('POST /Log2Server/@app',function($app){
			$device=Flight::request()->query->device;
			$logName=Flight::request()->query->name;
			$content=file_get_contents("php://input");
			Log2Server::record($app,$device,$logName,$content);
		});
	}

	// If you want to deploy this as raw PHP without framework, or within low-level capsulized framework, use this
	public static function commonPHPApi(){
		$app=$_GET['app']; //Or decided by hard code 
		$device=$_GET['device'];
		$logName=$_GET['name'];
		$content=file_get_contents("php://input");
		Log2Server::record($app,$device,$logName,$content);
	}

	// The real IO function, using file system.
	public static function record($app,$device,$logName,$content){
		$device_path=(Log2Server::$Log2Server_LogPath)."/".$app."/".$device;
		$path=$device_path."/".$logName;
		if(!file_exists($device_path)){
			$mkdir_ok=mkdir($device_path,0777,true);
		}
		$result=file_put_contents($path, $content);
		if(!empty($result)){
			echo json_encode(array('result'=>'ok'));
			exit();
		}else{
			echo json_encode(array('result'=>'failed'));
			exit();
		}
	}

}

?>