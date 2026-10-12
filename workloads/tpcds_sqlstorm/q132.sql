WITH sales_agg AS (
    SELECT
        CASE
            WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_sold_date_sk
            WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_sold_date_sk
            WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_sold_date_sk
        END AS sold_date_sk,
        COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
        COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0) + COALESCE(ws.ws_quantity, 0) AS total_quantity,
        COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) AS total_net_paid,
        COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) AS total_net_profit,
        COALESCE(cs.cs_sold_time_sk, ss.ss_sold_time_sk, ws.ws_sold_time_sk) AS sold_time_sk
    FROM catalog_sales cs
    FULL OUTER JOIN store_sales ss
        ON cs.cs_sold_date_sk = ss.ss_sold_date_sk
        AND cs.cs_item_sk = ss.ss_item_sk
    FULL OUTER JOIN web_sales ws
        ON COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk) = ws.ws_sold_date_sk
        AND COALESCE(cs.cs_item_sk, ss.ss_item_sk) = ws.ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_color,
        i.i_size,
        i.i_units
    FROM item i
),
date_bucket AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        d.d_month_seq,
        d.d_week_seq,
        d.d_dow,
        CASE WHEN d.d_week_seq % 2 = 0 THEN 'EVEN_WEEK' ELSE 'ODD_WEEK' END AS week_parity,
        DATE_FORMAT(d.d_date, '%Y-%m-%d') AS formatted_date
    FROM date_dim d
    WHERE d.d_date IS NOT NULL
),
promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_email,
        p.p_discount_active,
        CASE
            WHEN p.p_discount_active = 'Y' THEN CAST(p.p_cost * 0.9 AS DECIMAL(15,2))
            ELSE p.p_cost
        END AS effective_cost
    FROM promotion p
),
unified_sales AS (
    SELECT
        s.sold_date_sk,
        s.item_sk,
        s.total_quantity,
        s.total_net_paid,
        s.total_net_profit,
        d.d_year,
        d.d_quarter_name,
        d.week_parity,
        i.i_category,
        i.i_brand,
        i.i_color,
        i.i_size,
        i.i_units,
        COALESCE(p.effective_cost, 0) AS promo_cost,
        CASE WHEN s.total_quantity = 0 THEN NULL ELSE s.total_net_profit / nullif(s.total_quantity, 0) END AS profit_per_unit,
        ROW_NUMBER() OVER (PARTITION BY s.item_sk ORDER BY s.total_net_profit DESC) AS rn_item_profit_rank,
        COUNT(*) OVER (PARTITION BY d.d_year) AS sales_per_year,
        SUM(s.total_net_paid) OVER (
            PARTITION BY i.i_category
            ORDER BY s.sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_category_sales
    FROM sales_agg s
    LEFT JOIN date_bucket d ON s.sold_date_sk = d.d_date_sk
    LEFT JOIN item_details i ON s.item_sk = i.i_item_sk
    LEFT JOIN promo_info p ON i.i_item_sk = p.p_promo_sk
    WHERE (s.total_net_paid > 0 AND d.d_year BETWEEN 1999 AND 2002)
      AND (i.i_brand IS NOT NULL OR i.i_category IS NOT NULL)
      AND (p.p_discount_active IS NULL OR p.p_discount_active <> 'N')
),
top_items AS (
    SELECT
        us.item_sk,
        i.i_category,
        i.i_brand,
        MAX(us.profit_per_unit) AS max_profit_per_unit,
        COUNT(CASE WHEN us.profit_per_unit > 5 THEN 1 END) AS high_profit_count,
        array_join(array_agg(DISTINCT i.i_color), ',') AS colors_used
    FROM unified_sales us
    JOIN item_details i ON us.item_sk = i.i_item_sk
    GROUP BY us.item_sk, i.i_category, i.i_brand
    HAVING MAX(us.total_net_profit) > 1000
),
avg_profit AS (
    SELECT AVG(profit_per_unit) AS overall_avg_profit
    FROM unified_sales
    WHERE profit_per_unit IS NOT NULL
)
SELECT
    ti.item_sk,
    ti.i_category,
    ti.i_brand,
    ti.max_profit_per_unit,
    ti.high_profit_count,
    ti.colors_used,
    CASE
        WHEN ti.max_profit_per_unit > (SELECT overall_avg_profit FROM avg_profit) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_category,
    regexp_replace(
        concat(
            'Item ',
            CAST(ti.item_sk AS VARCHAR),
            ' (',
            ti.i_brand,
            '/',
            ti.i_category,
            ') ',
            'Profit/unit: ',
            CAST(round(ti.max_profit_per_unit, 2) AS VARCHAR),
            ' Colors: ',
            ti.colors_used
        ),
        '\\s+',
        ' '
    ) AS descriptive_label
FROM top_items ti
LEFT JOIN item_details i ON ti.item_sk = i.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = ti.item_sk
      AND cr.cr_return_quantity > 0
      AND cr.cr_returned_date_sk = (
          SELECT MAX(d_date_sk)
          FROM date_dim
          WHERE d_year = 2002
      )
)
UNION ALL
SELECT
    -1 AS item_sk,
    'TOTAL' AS i_category,
    NULL AS i_brand,
    MAX(max_profit_per_unit) AS max_profit_per_unit,
    SUM(high_profit_count) AS high_profit_count,
    NULL AS colors_used,
    'AGGREGATE' AS profit_category,
    'TOTAL_AGGREGATE' AS descriptive_label
FROM top_items
ORDER BY profit_category DESC, max_profit_per_unit DESC
LIMIT 50
