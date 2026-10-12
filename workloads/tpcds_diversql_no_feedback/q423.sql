WITH site_sales AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        w.web_city,
        w.web_gmt_offset,
        w.web_street_number,
        regexp_extract(w.web_name, '([^ ]+)') AS first_word,
        substring(w.web_name, 1, 3) AS name_prefix,
        CONCAT(regexp_extract(w.web_name, '([^ ]+)'), '_', w.web_city) AS site_key,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM
        web_sales ws
    RIGHT JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        w.web_gmt_offset = -5.00
        AND regexp_like(w.web_name, 'Shop')
        AND w.web_city LIKE 'A%'
    GROUP BY
        w.web_site_sk,
        w.web_name,
        w.web_city,
        w.web_gmt_offset,
        w.web_street_number,
        regexp_extract(w.web_name, '([^ ]+)'),
        substring(w.web_name, 1, 3),
        CONCAT(regexp_extract(w.web_name, '([^ ]+)'), '_', w.web_city)
)
SELECT
    web_site_sk,
    web_name,
    web_city,
    first_word,
    name_prefix,
    site_key,
    total_net_paid,
    SUM(total_net_paid) OVER (ORDER BY web_name) AS running_total,
    LAG(total_net_paid) OVER (ORDER BY web_name) AS prev_site_total
FROM
    site_sales
ORDER BY
    total_net_paid DESC
LIMIT 100
