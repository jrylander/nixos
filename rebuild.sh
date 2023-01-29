#!/bin/bash

nixos-rebuild switch --fast --use-remote-sudo --flake .#zwave --target-host zwave.rylander.cc --build-host zwave.rylander.cc
