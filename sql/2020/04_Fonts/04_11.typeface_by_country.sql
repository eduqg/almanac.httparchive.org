#standardSQL
#typeface by country
CREATE TEMPORARY FUNCTION getFontFamilies(css STRING)
RETURNS ARRAY < STRING > LANGUAGE js AS '''
try {
    var $ = JSON.parse(css);
    return $.stylesheet.rules.filter(rule => rule.type == 'font-face').map(rule => {
        var family = rule.declarations && rule.declarations.find(d => d.property == 'font-family');
        return family && family.value.replace(/[\'"]/g, '');
    }).filter(family => family);
} catch (e) {
    return [];
}
''';

SELECT
  client,
  font_family,
  country,
  freq_typeface,
  total_typeface,
  pct
FROM (
  SELECT
    client,
    font_family,
    country,
    COUNT(0) AS freq_typeface,
    SUM(COUNT(0)) OVER (PARTITION BY client) AS total_typeface,
    ROUND(COUNT(0) * 100 / SUM(COUNT(0)) OVER (PARTITION BY client), 2) AS pct,
    ROW_NUMBER() OVER (PARTITION BY client, country ORDER BY COUNT(0) DESC) AS rank
  FROM
    `httparchive.almanac.parsed_css`,
    UNNEST(getFontFamilies(css)) AS font_family
  JOIN (
    SELECT
      DISTINCT origin,
      `chrome-ux-report`.experimental.GET_COUNTRY(country_code) AS country
    FROM
      `chrome-ux-report.materialized.country_summary`
    WHERE
      yyyymm=202008)
  ON
    CONCAT(origin, '/')=page
  WHERE
    date='2020-08-01'
  GROUP BY
    client,
    font_family,
    country
  ORDER BY
    client, font_family, freq_typeface DESC)
WHERE
  rank<=10