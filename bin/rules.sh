#! /bin/bash

post_rule() {
    echo "start post rules with file $1 ..."
    curl -X POST -H 'X-Scope-OrgID: demo' -H 'content-type:application/yaml' --data-binary "@$1"  http://localhost:8001/api/v1/rules/cortex
    echo ""
}

rules_dir=./config/cortex/rules
for entry in "$rules_dir"/* 
do 
    post_rule $entry
done 

