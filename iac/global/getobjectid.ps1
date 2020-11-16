# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

$t = az ad signed-in-user show
$t = "$t"
$j = ConvertFrom-Json $t
Write-Output "{`"object_id`":`"$($j.objectId)`"}"