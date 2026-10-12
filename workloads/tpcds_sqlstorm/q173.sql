WITH sales_by_channel AS (
    SELECT
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        i.i_category,
        i.i_color,
        COALESCE(ss.ss_quantity, 0) * COALESCE(i.i_current_price, 0) AS estimated_revenue,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn_customer_sales,
        SUM(ss.ss_net_paid) OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
        CASE WHEN i.i_color IS NULL THEN 'UNKNOWN' ELSE i.i_color END AS item_color_norm
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
),
web_sales_by_channel AS (
    SELECT
        'web' AS sales_channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        i.i_category,
        i.i_color,
        COALESCE(ws.ws_quantity, 0) * COALESCE(i.i_current_price, 0) AS estimated_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn_customer_sales,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
        CASE WHEN i.i_color IS NULL THEN 'UNKNOWN' ELSE i.i_color END AS item_color_norm
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
sales_union AS (
    SELECT * FROM sales_by_channel
    UNION ALL
    SELECT * FROM web_sales_by_channel
),
catalog_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_category,
        i.i_color,
        d.d_year,
        cs.cs_sold_date_sk AS date_sk,
        CASE
            WHEN cs.cs_quantity > 5 THEN 'Bulk'
            ELSE 'Regular'
        END AS sale_type,
        CONCAT_WS(':', i.i_item_id, CAST(d.d_date_id AS VARCHAR)) AS item_date_key,
        cs.cs_net_profit / NULLIF(cs.cs_quantity, 0) AS profit_per_item,
        (SELECT MAX(cr.cr_return_amount) FROM catalog_returns cr WHERE cr.cr_order_number = cs.cs_order_number) AS max_return_amount,
        CASE WHEN EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_quantity > 0
        ) THEN 1 ELSE 0 END AS has_return
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE (i.i_color = 'Red' OR i.i_color IS NULL)
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
),
final AS (
    SELECT
        su.sales_channel,
        s.c_customer_id,
        s.c_first_name,
        s.c_last_name,
        su.date_sk,
        d.d_date,
        su.item_sk,
        i.i_product_name,
        su.item_color_norm,
        su.estimated_revenue,
        su.cumulative_net_paid,
        su.rn_customer_sales,
        ca.sale_type,
        ca.item_date_key,
        ROUND(ca.profit_per_item, 2) AS profit_per_item,
        COALESCE(ca.max_return_amount, 0) AS max_return_amount,
        ca.has_return,
        SUM(su.estimated_revenue) OVER (PARTITION BY su.sales_channel, d.d_year) AS revenue_by_year_channel,
        RANK() OVER (PARTITION BY su.sales_channel ORDER BY su.cumulative_net_paid DESC) AS revenue_rank_channel,
        CASE WHEN COALESCE(s.c_preferred_cust_flag, 'N') = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_tier,
        CASE
            WHEN REGEXP_LIKE(i.i_category, '^E.*') THEN 'Electronics'
            WHEN REGEXP_LIKE(i.i_category, '^F.*') THEN 'Food'
            ELSE 'Other'
        END AS category_group,
        DATE_DIFF('day', d.d_date, DATE '2024-10-01') AS days_since_sale,
        TRY_CAST(i.i_current_price AS DOUBLE) * 1.0 AS price_as_double,
        APPROX_PERCENTILE(ca.profit_per_item, 0.5) OVER () AS median_profit_per_item
    FROM sales_union su
    LEFT JOIN catalog_agg ca
        ON su.item_sk = ca.cs_item_sk
       AND su.date_sk = ca.date_sk
    LEFT JOIN customer s ON su.customer_sk = s.c_customer_sk
    LEFT JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    WHERE (su.sales_channel = 'store' AND su.cumulative_net_paid > 0)
       OR (su.sales_channel = 'web' AND su.estimated_revenue > 100)
)
SELECT *
FROM final
WHERE rn_customer_sales <= 5
  AND (revenue_by_year_channel > 10000 OR revenue_by_year_channel IS NULL)
  AND (customer_tier = 'Preferred' OR profit_per_item IS NULL)
ORDER BY sales_channel, revenue_rank_channel, days_since_sale DESC
LIMIT 100
