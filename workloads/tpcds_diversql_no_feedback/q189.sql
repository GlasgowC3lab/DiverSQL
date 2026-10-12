WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_item_desc,
        i.i_color,
        i.i_size,
        cp.cp_catalog_page_id,
        cp.cp_description,
        sm.sm_ship_mode_id
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '(?i)brand|model')
      AND cp.cp_type LIKE 'C%'
)
SELECT
    s.cp_catalog_page_id,
    substring(s.cp_description, 1, 20) AS short_desc,
    concat(s.i_color, '-', s.i_size) AS item_variant,
    COUNT(*) AS sales_cnt,
    SUM(s.cs_quantity) AS total_qty,
    SUM(s.cs_net_profit) AS total_profit
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = s.cs_order_number
          AND cr.cr_return_amount > 0
          AND regexp_extract(s.i_item_desc, '(\\d{4})', 1) IS NOT NULL
    )
GROUP BY
    s.cp_catalog_page_id,
    substring(s.cp_description, 1, 20),
    concat(s.i_color, '-', s.i_size)
ORDER BY total_profit DESC
LIMIT 100
