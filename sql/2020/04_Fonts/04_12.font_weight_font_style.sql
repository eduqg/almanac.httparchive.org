#standardSQL
#font_weight_font_style(??Invalid_NUMERIC_value)
CREATE TEMPORARY FUNCTION getFonts(css STRING)
RETURNS ARRAY<STRUCT<weight STRING, style STRING>> LANGUAGE js AS '''
try {
    var reduceValues = (values, rule) => {
        if ('rules' in rule) {
            return rule.rules.reduce(reduceValues, values);
        }
        if (!('declarations' in rule)) {
            return values;
        }
        if (rule.type != 'font-face') {
            return values;
        }
        var props = {};
        rule.declarations.forEach(d => {
            if (d.property.toLowerCase() == 'font-weight') {
                props.weight = d.value;
            } else if (d.property.toLowerCase() == 'font-style') {
                props.style = d.value;
            }
        });
        if (props.weight && props.style) {
            values.push(props);
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
  COUNTIF(italic > 0) AS freq_italic,
  COUNTIF(oblique > 0) AS freq_oblique,
  COUNTIF(style_normal > 0) AS freq_style_normal,
  COUNTIF(weight_400_normal > 0) AS freq_weight_400_normal,
  COUNTIF(weight_700_bold > 0) AS freq_weight_700_bold,
  COUNTIF(lighter > 0) AS freq_lighter,
  COUNTIF(bolder > 0) AS freq_bolder,
  total_page,
  ROUND(COUNTIF(italic > 0) * 100 / total_page, 2) AS pct_italic,
  ROUND(COUNTIF(oblique > 0) * 100 / total_page, 2) AS pct_oblique,
  ROUND(COUNTIF(style_normal > 0) * 100 / total_page, 2) AS pct_style_normal,
  ROUND(COUNTIF(weight_400_normal > 0) * 100 / total_page, 2) AS pct_weight_400_normal,
  ROUND(COUNTIF(weight_700_bold > 0) * 100 / total_page, 2) AS pct_weight_700_bold,
  ROUND(COUNTIF(lighter > 0) * 100 / total_page, 2) AS pct_lighter,
  ROUND(COUNTIF(bolder > 0) * 100 / total_page, 2) AS pct_bolder
FROM (
  SELECT
    client,
    COUNTIF(font.style = 'italic') AS italic,
    COUNTIF(font.style = 'oblique') AS oblique,
    COUNTIF(font.style = 'normal') AS style_normal,
    COUNTIF(font.weight = 'normal'
      OR font.weight = '400') AS weight_400_normal,
    COUNTIF(font.weight = 'bold'
      OR font.weight = '700') AS weight_700_bold,
    COUNTIF(font.weight != 'normal'
      AND (font.weight = 'bold'
        OR (CAST(font.weight AS NUMERIC) > 400))) AS bolder,
    COUNTIF(font.weight != 'normal'
      AND font.weight != 'bold'
      AND (CAST(font.weight AS NUMERIC) < 400)) AS lighter
  FROM
    `httparchive.almanac.parsed_css`,
    UNNEST(getFonts(css)) AS font
  WHERE
    date='2020-08-01'
  GROUP BY
    client,
    page)
JOIN (
  SELECT
    _TABLE_SUFFIX AS client,
    COUNT(0) AS total_page
  FROM
    `httparchive.summary_pages.2020_08_01_*`
  GROUP BY
    _TABLE_SUFFIX)
USING
  (client)
GROUP BY
  client,
  total_page