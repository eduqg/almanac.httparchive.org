#standardSQL
# 22_HTTP_2 - % of sites affected by CDN prioritization issues (H2 and served by CDN)
SELECT 
  client,
  IF(pages.cdn = "", "Not using CDN", pages.cdn) AS CDN,
  IF(prioritization_status IS NOT null, prioritization_status, "Unknown") prioritizes_correctly,
  COUNT(*) AS num_pages,
  ROUND(COUNT(0) * 100 / SUM(COUNT(0)) OVER (PARTITION BY client), 2) AS pct
FROM 
  (
    SELECT
      date,
      client,
      url,
      JSON_EXTRACT_SCALAR(payload, "$._cdn_provider") as cdn
    FROM 
      `httparchive.almanac.requests` 
    WHERE 
      JSON_EXTRACT_SCALAR(payload, "$._protocol") ="HTTP/2"
      AND firstHtml
      AND date='2020-08-01'
  ) AS pages
LEFT JOIN 
  `httparchive.almanac.h2_prioritization_cdns` AS h2_pri
ON pages.cdn = h2_pri.cdn
AND pages.date = h2_pri.date
GROUP BY
  client,
  CDN,
  prioritizes_correctly
ORDER BY num_pages DESC
