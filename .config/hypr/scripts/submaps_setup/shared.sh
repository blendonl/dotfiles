#!/bin/bash

show_indicator() {
    qs ipc call indicator showSubmap "$1"
}

hide_indicator() {
    qs ipc call indicator hide
}
