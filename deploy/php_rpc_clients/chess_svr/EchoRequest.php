<?php
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: chess.proto

namespace Chess;

use Google\Protobuf\Internal\GPBType;
use Google\Protobuf\Internal\RepeatedField;
use Google\Protobuf\Internal\GPBUtil;

/**
 * Protobuf type <code>chess.EchoRequest</code>
 */
class EchoRequest extends \Google\Protobuf\Internal\Message
{
    /**
     * <code>string msg = 1;</code>
     */
    private $msg = '';

    public function __construct() {
        \GPBMetadata\Chess::initOnce();
        parent::__construct();
    }

    /**
     * <code>string msg = 1;</code>
     */
    public function getMsg()
    {
        return $this->msg;
    }

    /**
     * <code>string msg = 1;</code>
     */
    public function setMsg($var)
    {
        GPBUtil::checkString($var, True);
        $this->msg = $var;
    }

}

