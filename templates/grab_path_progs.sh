#!/bin/bash

ls -1 $1 | tr '\n' ' ' | sed 's# #","#g'
