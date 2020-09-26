#standardSQL
#icon_fonts 
CREATE TEMPORARY FUNCTION checksSupports(css STRING)
RETURNS ARRAY<STRING> LANGUAGE js AS '''
try {
    var reduceValues = (values, rule) => {
        if (rule.type == 'stylesheet' && rule.supports.toLowerCase().includes('icon')) {
            values.push(rule.supports.toLowerCase());
        }
        return values;
    };
    var $ = JSON.parse(css);
    return $.stylesheet.rules.reduce(reduceValues, []);
} catch (e) {
    return [];
}
''';

SELECT
 client,
 NET.HOST(url) AS url,
 COUNT(DISTINCT page) AS freq_ficon,
 total_page,
 ROUND(COUNT(DISTINCT page) * 100 / total_page, 2) AS pct_ficon
FROM
 `httparchive.almanac.parsed_css`
JOIN
 (SELECT _TABLE_SUFFIX AS client, COUNT(0) AS total_page FROM `httparchive.summary_pages.2020_08_01_*` GROUP BY _TABLE_SUFFIX)
USING
 (client)
WHERE
 ARRAY_LENGTH(checksSupports(css)) > 0 AND date='2020-08-01' OR url LIKE '%fontawesome%' OR url LIKE '%icomoon%' 
GROUP BY
 client, url, total_page
ORDER BY
 client, freq_ficon DESC