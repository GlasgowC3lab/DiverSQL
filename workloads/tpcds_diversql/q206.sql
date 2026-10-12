SELECT
    web_name,
    web_city,
    web_state,
    web_tax_percentage
FROM
    web_site
WHERE
    web_street_type = 'Drive'
    AND web_county = 'Williamson County'
ORDER BY
    web_name
LIMIT 10
