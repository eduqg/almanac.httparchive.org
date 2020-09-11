#standardSQL
# 22_HTTP_2 - Measure number of TCP Connections per site.
SELECT 
  "mobile" AS client,
  JSON_EXTRACT_SCALAR(payload, "$._protocol") AS protocol,
  COUNT(*) AS num_pages,
  APPROX_QUANTILES(_connections, 100)[SAFE_ORDINAL(50)] AS median,
  APPROX_QUANTILES(_connections, 100)[SAFE_ORDINAL(75)] AS p75,
  APPROX_QUANTILES(_connections, 100)[SAFE_ORDINAL(95)] AS p95
FROM 
  `httparchive.requests.2020_08_01_mobile` AS requests
INNER JOIN
  `httparchive.summary_pages.2020_08_01_mobile` AS summary
ON
  requests.url = summary.url
WHERE
  JSON_EXTRACT_SCALAR(payload, "$._is_base_page") = "true"
GROUP BY 
  client, 
  protocol

UNION ALL

SELECT 
  "desktop" AS client,
  JSON_EXTRACT_SCALAR(payload, "$._protocol") AS protocol,
  COUNT(*) AS num_pages,
  APPROX_QUANTILES(_connections, 100)[SAFE_ORDINAL(50)] AS median,
  APPROX_QUANTILES(_connections, 100)[SAFE_ORDINAL(75)] AS p75,
  APPROX_QUANTILES(_connections, 100)[SAFE_ORDINAL(95)] AS p95
FROM 
  `httparchive.requests.2020_08_01_desktop` AS requests
INNER JOIN
  `httparchive.summary_pages.2020_08_01_desktop` AS summary
ON
  requests.url = summary.url
WHERE
  JSON_EXTRACT_SCALAR(payload, "$._is_base_page") = "true"
GROUP BY 
  client, 
  protocol
