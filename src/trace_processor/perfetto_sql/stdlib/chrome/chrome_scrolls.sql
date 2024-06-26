-- Copyright 2023 The Chromium Authors
-- Use of this source code is governed by a BSD-style license that can be
-- found in the LICENSE file.

INCLUDE PERFETTO MODULE chrome.scroll_jank.utils;

-- Defines slices for all of the individual scrolls in a trace based on the
-- LatencyInfo-based scroll definition.
--
-- NOTE: this view of top level scrolls is based on the LatencyInfo definition
-- of a scroll, which differs subtly from the definition based on
-- EventLatencies.
-- TODO(b/278684408): add support for tracking scrolls across multiple Chrome/
-- WebView instances. Currently gesture_scroll_id unique within an instance, but
-- is not unique across multiple instances. Switching to an EventLatency based
-- definition of scrolls should resolve this.
CREATE PERFETTO TABLE chrome_scrolls(
  -- The unique identifier of the scroll.
  id INT,
  -- The start timestamp of the scroll.
  ts INT,
  -- The duration of the scroll.
  dur INT,
  -- The earliest timestamp of the EventLatency slice of the GESTURE_SCROLL_BEGIN type for the
  -- corresponding scroll id.
  gesture_scroll_begin_ts INT,
  -- The earliest timestamp of the EventLatency slice of the GESTURE_SCROLL_END type /
  -- the latest timestamp of the EventLatency slice of the GESTURE_SCROLL_UPDATE type for the
  -- corresponding scroll id.
  gesture_scroll_end_ts INT
) AS
WITH all_scrolls AS (
  SELECT
    args.string_value AS name,
    S.ts AS ts,
    S.dur AS dur,
    chrome_get_most_recent_scroll_begin_id(S.ts) AS scroll_id
  FROM slice AS S JOIN args USING(arg_set_id)
  WHERE name="EventLatency"
  AND args.string_value GLOB "*GESTURE_SCROLL*"
),
scroll_starts AS (
  SELECT
    scroll_id,
    MIN(ts) AS gesture_scroll_begin_ts
  FROM all_scrolls
  WHERE name = "GESTURE_SCROLL_BEGIN"
  GROUP BY scroll_id
),
scroll_ends AS (
  SELECT
    scroll_id,
    MAX(ts) AS gesture_scroll_end_ts
  FROM all_scrolls
  WHERE name GLOB "*GESTURE_SCROLL_UPDATE"
    OR name = "GESTURE_SCROLL_END"
  GROUP BY scroll_id
)
SELECT
  sa.scroll_id AS id,
  MIN(ts) AS ts,
  CAST(MAX(ts + dur) - MIN(ts) AS INT) AS dur,
  ss.gesture_scroll_begin_ts AS gesture_scroll_begin_ts,
  se.gesture_scroll_end_ts AS gesture_scroll_end_ts
FROM all_scrolls sa
  LEFT JOIN scroll_starts ss ON
    sa.scroll_id = ss.scroll_id
  LEFT JOIN scroll_ends se ON
    sa.scroll_id = se.scroll_id
GROUP BY sa.scroll_id;

-- Defines slices for all of scrolls intervals in a trace based on the scroll
-- definition in chrome_scrolls. Note that scrolls may overlap (particularly in
-- cases of jank/broken traces, etc); so scrolling intervals are not exactly the
-- same as individual scrolls.
CREATE PERFETTO VIEW chrome_scrolling_intervals(
  -- The unique identifier of the scroll interval. This may span multiple scrolls if they overlap.
  id INT,
  -- Comma-separated list of scroll ids that are included in this interval.
  scroll_ids STRING,
  -- The start timestamp of the scroll interval.
  ts INT,
  -- The duration of the scroll interval.
  dur INT
) AS
WITH all_scrolls AS (
  SELECT
    id AS scroll_id,
    s.ts AS start_ts,
    s.ts + s.dur AS end_ts
  FROM chrome_scrolls s),
ordered_end_ts AS (
  SELECT
    *,
    MAX(end_ts) OVER (ORDER BY start_ts) AS max_end_ts_so_far
  FROM all_scrolls),
range_starts AS (
  SELECT
    *,
    CASE
      WHEN start_ts <= 1 + LAG(max_end_ts_so_far) OVER (ORDER BY start_ts) THEN 0
      ELSE 1
    END AS range_start
  FROM ordered_end_ts),
range_groups AS (
  SELECT
    *,
    SUM(range_start) OVER (ORDER BY start_ts) AS range_group
  FROM range_starts)
SELECT
  range_group AS id,
  GROUP_CONCAT(scroll_id) AS scroll_ids,
  MIN(start_ts) AS ts,
  MAX(end_ts) - MIN(start_ts) AS dur
FROM range_groups
GROUP BY range_group;
