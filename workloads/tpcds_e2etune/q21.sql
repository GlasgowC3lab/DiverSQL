WITH store_agg AS (
    SELECT
        s_state,
        s_market_id,
        s_market_desc,
        COUNT(*) AS store_cnt,
        SUM(s_floor_space) AS total_floor_space,
        AVG(s_number_employees) AS avg_employees,
        AVG(s_tax_percentage) AS avg_store_tax,
        MIN(s_rec_start_date) AS earliest_store_open
    FROM store
    WHERE s_rec_start_date >= DATE '2015-01-01'
      AND s_country = 'United States'
      AND s_state IN ('AL', 'NC', 'MN')
    GROUP BY s_state, s_market_id, s_market_desc
),
website_agg AS (
    SELECT
        web_mkt_id,
        COUNT(DISTINCT web_site_id) AS website_cnt,
        AVG(web_tax_percentage) AS avg_web_tax,
        MIN(web_rec_start_date) AS earliest_website_open
    FROM web_site
    WHERE web_rec_start_date >= DATE '2015-01-01'
      AND web_country = 'United States'
    GROUP BY web_mkt_id
)
SELECT
    s.s_state,
    s.s_market_id,
    s.s_market_desc,
    s.store_cnt,
    s.total_floor_space,
    s.avg_employees,
    s.avg_store_tax,
    w.website_cnt,
    w.avg_web_tax,
    (s.total_floor_space / NULLIF(w.website_cnt, 0)) AS floor_space_per_website,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY s.total_floor_space DESC) AS state_floor_space_rank,
    CASE
        WHEN s.total_floor_space > 1000000 THEN 'Large'
        WHEN s.total_floor_space > 500000 THEN 'Medium'
        ELSE 'Small'
    END AS size_category
FROM store_agg s
LEFT JOIN website_agg w
    ON s.s_market_id = w.web_mkt_id
WHERE s.store_cnt >= 5
ORDER BY s.s_state, s.total_floor_space DESC
LIMIT 100
