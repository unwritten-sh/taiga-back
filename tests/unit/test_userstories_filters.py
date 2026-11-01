# -*- coding: utf-8 -*-
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos INC

from unittest import mock

import pytest

from taiga.base import exceptions as exc
from taiga.projects.userstories.filters import UserStoryStatusesFilter


def test_userstory_statuses_filter_with_non_integer_project_raises_bad_request():
    request = mock.Mock(QUERY_PARAMS={"project": "abc"})
    queryset = mock.Mock()

    with pytest.raises(exc.BadRequest):
        UserStoryStatusesFilter().filter_queryset(request, queryset, view=None)
