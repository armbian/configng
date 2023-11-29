#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.



# @description Set a local net test.
#
# @exitcode 0  If successful.
#
# @options none
function network::nmtui(){
	nmtui connect
    return 0
}
