#standardSQL
#variable_font_with_fcp
SELECT
 client,
 NET.HOST(url),
 COUNT(DISTINCT page) AS freq_vf,
 total_page,
 ROUND(COUNT(DISTINCT page) * 100 / total_page, 2) AS pct_vf,
 ROUND(COUNTIF(fast_fcp>=0.75)*100/count(0),0) as pct_fast_fcp_vf,
 ROUND(COUNTIF(NOT(slow_fcp >=0.25) AND NOT(fast_fcp>=0.75))*100/count(0),0) as pct_avg_fcp_vf,
 ROUND(COUNTIF(slow_fcp>=0.25)*100/count(0),0) as pct_slow_fcp_vf,
FROM
 `httparchive.almanac.requests`
JOIN
 (SELECT _TABLE_SUFFIX AS client, COUNT(0) AS total_page FROM `httparchive.summary_pages.2020_08_01_*` GROUP BY _TABLE_SUFFIX) #FROM `httparchive.summary_pages.2020_08_01_*`
USING
 (client)
join
 (select origin, fast_fcp, slow_fcp,
from
 `chrome-ux-report.materialized.device_summary` where yyyymm=202007)
ON
 concat(origin, '/')= url
WHERE
 type = 'font' AND
 JSON_EXTRACT_SCALAR(payload, '$._font_details.table_sizes.gvar') IS NOT NULL OR
 CAST(JSON_EXTRACT_SCALAR(payload, '$._font_details.table_sizes.fvar.axisCount') AS NUMERIC) >0
GROUP BY
 client, url, total_page