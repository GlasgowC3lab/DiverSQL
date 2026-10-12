WITH brand_stats AS (
    SELECT
        i.i_brand,
        ib.ib_income_band_sk,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        AVG(i.i_current_price) AS avg_price,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost,
        MIN(i.i_rec_start_date) AS earliest_item_date,
        MAX(ws.web_open_date_sk) AS latest_site_open_sk
    FROM income_band ib
    JOIN item i ON ib.ib_income_band_sk = i.i_brand_id
    JOIN web_site ws ON i.i_manufact_id = ws.web_mkt_id
    WHERE ib.ib_lower_bound >= 20000
      AND ws.web_state = 'CA'
      AND i.i_current_price > 20
    GROUP BY i.i_brand, ib.ib_income_band_sk
)
SELECT
    i_brand,
    ib_income_band_sk,
    distinct_items,
    avg_price,
    total_wholesale_cost,
    earliest_item_date,
    latest_site_open_sk,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY avg_price DESC) AS price_rank
FROM brand_stats
ORDER BY ib_income_band_sk, price_rank
LIMIT 100
