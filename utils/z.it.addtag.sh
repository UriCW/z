#!/bin/bash
#echo "add_tag({label=\"$1\", rules={delete_when_empty=true} })" | awesome-client
echo "add_tag({label=\"$@\",rules={delete_when_empty=true}})" | awesome-client

