<?php
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: chess.proto

namespace Chess;

use Google\Protobuf\Internal\GPBType;
use Google\Protobuf\Internal\RepeatedField;
use Google\Protobuf\Internal\GPBUtil;

/**
 * Protobuf type <code>chess.MonitorResult</code>
 */
class MonitorResult extends \Google\Protobuf\Internal\Message
{
    /**
     * <code>int32 ret = 1;</code>
     */
    private $ret = 0;
    /**
     * <code>string retmsg = 2;</code>
     */
    private $retmsg = '';

    public function __construct() {
        \GPBMetadata\Chess::initOnce();
        parent::__construct();
    }

    /**
     * <code>int32 ret = 1;</code>
     */
    public function getRet()
    {
        return $this->ret;
    }

    /**
     * <code>int32 ret = 1;</code>
     */
    public function setRet($var)
    {
        GPBUtil::checkInt32($var);
        $this->ret = $var;
    }

    /**
     * <code>string retmsg = 2;</code>
     */
    public function getRetmsg()
    {
        return $this->retmsg;
    }

    /**
     * <code>string retmsg = 2;</code>
     */
    public function setRetmsg($var)
    {
        GPBUtil::checkString($var, True);
        $this->retmsg = $var;
    }

}

