<?php
namespace Log2Server;

/**
* Advanced Log2Server
* According to PSR2 standard.
* Appendable Logging.
*/
class Log2Server
{
    private $logDir;

    public function setLogDir($path)
    {
        $this->logDir=$path;
    }
    public function getLogDir($path)
    {
        return $this->logDir;
    }
    
    public function __construct($path)
    {
        $this->logDir=$path;
    }

    // The real IO function, using file system.
    private function record($app, $device, $logName, $content)
    {
        $device_path=$this->logDir."/".$app."/".$device;
        $path=$device_path."/".$logName;
        if (!file_exists($device_path)) {
            $mkdir_ok=mkdir($device_path, 0777, true);
        }
        $logName=str_replace(array("\\",'/'), '_', $logName);
        $result=file_put_contents($path, $content, FILE_APPEND);
        if (!empty($result)) {
            echo json_encode(array('result'=>'ok'));
            exit();
        } else {
            echo json_encode(array('result'=>'failed'));
            exit();
        }
    }

    // If you want to deploy this as raw PHP without framework, or within low-level capsulized framework, use this
    public function commonPHPApi()
    {
        $app=$this->safeGET('app', 'UNKNOWN'); //Or decided by hard code
        $device=$this->safeGET('device', 'UNKNOWN');
        $logName=$this->safeGET('name', 'UNKNOWN');
        $content=file_get_contents("php://input");
        $this->record($app, $device, $logName, $content);
    }

    public function safeGET($name, $default = null)
    {
        if (isset($_GET[$name]) && !empty($_GET[$name])) {
            return $_GET[$name];
        } else {
            return $default;
        }
    }
}
