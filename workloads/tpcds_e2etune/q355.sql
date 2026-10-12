WITH store_agg AS (
    SELECT s_state AS state,
           s_city AS city,
           COUNT(*) AS store_cnt,
           AVG(s_floor_space) AS avg_floor_space,
           AVG(s_tax_percentage) AS avg_store_tax
    FROM store
    WHERE s_number_employees > 100
      AND s_closed_date_sk IS NULL
    GROUP BY s_state, s_city
),
website_agg AS (
    SELECT web_state AS state,
           web_city AS city,
           COUNT(*) AS website_cnt,
           AVG(web_tax_percentage) AS avg_website_tax
    FROM web_site
    WHERE web_open_date_sk IS NOT NULL
    GROUP BY web_state, web_city
),
customer_agg AS (
    SELECT ca_state AS state,
           ca_city AS city,
           COUNT(*) AS customer_cnt
    FROM customer_address
    GROUP BY ca_state, ca_city
)
SELECT
    s.state,
    s.city,
    s.store_cnt,
    w.website_cnt,
    c.customer_cnt,
    s.avg_floor_space,
    s.avg_store_tax,
    w.avg_website_tax,
    (s.avg_store_tax - w.avg_website_tax) AS tax_diff,
    RANK() OVER (ORDER BY (s.avg_store_tax - w.avg_website_tax) DESC) AS tax_diff_rank
FROM store_agg s
JOIN website_agg w
  ON s.state = w.state AND s.city = w.city
JOIN customer_agg c
  ON s.state = c.state AND s.city = c.city
WHERE s.store_cnt >= 5
  AND c.customer_cnt >= 100
ORDER BY tax_diff_rank
LIMIT 10
