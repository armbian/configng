#!/bin/bash

# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.



# @description Network Manager.
# @requirments armbiam-monitor,
# @exitcode 0  If successful.
# @default connect
# @options connect
function network::NMTUI(){
	nmtui connect
    return 0
}
