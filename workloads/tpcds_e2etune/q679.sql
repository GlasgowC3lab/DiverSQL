WITH store_filtered AS (
    SELECT
        s_store_sk,
        s_market_id,
        s_state,
        s_city,
        s_floor_space,
        s_tax_percentage
    FROM store
    WHERE s_rec_end_date > DATE '2000-01-01'
      AND s_tax_percentage BETWEEN 0.05 AND 0.10
),
web_filtered AS (
    SELECT
        web_site_sk,
        web_mkt_id,
        web_state,
        web_city,
        web_tax_percentage
    FROM web_site
    WHERE web_rec_end_date > DATE '2000-01-01'
)
SELECT
    state,
    city,
    market_id,
    num_stores,
    num_web_sites,
    total_floor_space,
    avg_store_tax,
    avg_web_tax,
    high_tax_floor_space,
    total_floor_space / NULLIF(num_stores, 0) AS avg_floor_space_per_store,
    RANK() OVER (ORDER BY total_floor_space DESC) AS floor_space_rank
FROM (
    SELECT
        s.s_state AS state,
        s.s_city AS city,
        s.s_market_id AS market_id,
        COUNT(DISTINCT s.s_store_sk) AS num_stores,
        COUNT(DISTINCT w.web_site_sk) AS num_web_sites,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_tax_percentage) AS avg_store_tax,
        AVG(w.web_tax_percentage) AS avg_web_tax,
        SUM(CASE WHEN s.s_tax_percentage > 0.07 THEN s.s_floor_space ELSE 0 END) AS high_tax_floor_space
    FROM store_filtered s
    JOIN web_filtered w
      ON s.s_market_id = w.web_mkt_id
     AND s.s_state = w.web_state
    GROUP BY s.s_state, s.s_city, s.s_market_id
    HAVING COUNT(DISTINCT s.s_store_sk) >= 5
) agg
ORDER BY floor_space_rank
LIMIT 100
