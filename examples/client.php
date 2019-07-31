<?php
/**
 * Log class
 */
class Log
{
    //发送udp日志
    public static function send($content, $ip, $port)
    {
        if (!function_exists('socket_create')) {
            return true;
        }

        $socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
        if (!$socket) {
            return false;
        }
        socket_set_option($socket, SOL_SOCKET, SO_SNDTIMEO, ["sec" => 0, "usec" => 100000]);
        socket_sendto($socket, $content, strlen($content), 0, $ip, $port);
        socket_close($socket);
    }
}
$str = time();
Log::send($str, '127.0.0.1', 34254);
var_dump(111);