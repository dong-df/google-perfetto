#!/usr/bin/env python3
# Copyright (C) 2023 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License a
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from python.generators.diff_tests.testing import Path, Metric
from python.generators.diff_tests.testing import Csv, Json, TextProto
from python.generators.diff_tests.testing import DiffTestBlueprint
from python.generators.diff_tests.testing import DiffTestModule


class DiffTestModule_Functions(DiffTestModule):

  def test_first_non_null_frame(self):
    return DiffTestBlueprint(
        trace=Path('../common/empty.textproto'),
        query=Path('first_non_null_frame_test.sql'),
        out=Csv("""
"id","val"
1,3
2,4
3,4
4,4
5,"[NULL]"
6,"[NULL]"
7,"[NULL]"
"""))

  def test_first_non_null_partition(self):
    return DiffTestBlueprint(
        trace=Path('../common/empty.textproto'),
        query=Path('first_non_null_partition_test.sql'),
        out=Csv("""
"id","val"
1,1
2,1
3,3
4,"[NULL]"
5,5
6,5
7,7
"""))

  def test_first_non_null(self):
    return DiffTestBlueprint(
        trace=Path('../common/empty.textproto'),
        query=Path('first_non_null_test.sql'),
        out=Csv("""
"id","val"
1,1
2,1
3,3
4,4
5,4
6,4
7,4
"""))
