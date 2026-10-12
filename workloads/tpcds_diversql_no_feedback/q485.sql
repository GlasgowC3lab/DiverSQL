WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        ss.ss_net_profit,
        ss.ss_quantity,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_code
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_am_pm = 'PM'
      AND regexp_like(i.i_product_name, '(Deluxe|Premium)')
      AND i.i_product_name LIKE '%Special%'
      AND concat(i.i_brand, '-', i.i_category) LIKE 'B%-%C%'
)
SELECT
    f.ss_store_sk,
    f.i_item_id,
    f.i_product_name,
    f.product_code,
    SUM(f.ss_net_profit) AS total_net_profit,
    SUM(f.ss_quantity) AS total_quantity,
    f.ib_lower_bound,
    f.ib_upper_bound
FROM filtered_sales f
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_ticket_number = f.ss_ticket_number
)
GROUP BY
    f.ss_store_sk,
    f.i_item_id,
    f.i_product_name,
    f.product_code,
    f.ib_lower_bound,
    f.ib_upper_bound
ORDER BY total_net_profit DESC
LIMIT 100
