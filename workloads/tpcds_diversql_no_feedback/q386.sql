/*
Goal: Identify high‑value catalog sales, enrich them with customer and item attributes, flag profit levels, rank each customer by profit, expand each sale into metric rows via UNNEST, attach a small set of years via a cross‑join, and expose any return reasons from store or web channels.
*/
WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_item_sk AS item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cp.cp_department,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_state
    FROM catalog_sales cs
    JOIN item i               ON cs.cs_item_sk      = i.i_item_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca  ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 1                                    -- predicate 1
      AND cs.cs_sales_price >= 20                               -- predicate 2
      AND i.i_brand = 'Brand1'                                 -- predicate 3
      AND cp.cp_department = 'Sports'                           -- predicate 4
      AND ca.ca_state = 'CA'                                    -- predicate 5
      AND cd.cd_gender = 'M'                                    -- predicate 6
)
SELECT
    sb.cs_order_number,
    sb.cs_sold_date_sk,
    sb.cs_quantity,
    sb.cs_sales_price,
    sb.cs_net_profit,
    sb.i_item_id,
    sb.i_brand,
    sb.i_category,
    sb.cp_department,
    sb.c_first_name,
    sb.c_last_name,
    sb.cd_gender,
    sb.ca_state,
    CASE
        WHEN sb.cs_net_profit > 100 THEN 'High'
        WHEN sb.cs_net_profit > 0   THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY sb.c_customer_sk ORDER BY sb.cs_net_profit DESC) AS profit_rank,
    metric,
    metric_value,
    yr.sold_year,
    COALESCE(r_store.r_reason_desc, r_web.r_reason_desc) AS return_reason
FROM sales_base sb
LEFT JOIN store_returns sr        ON sr.sr_item_sk = sb.item_sk
LEFT JOIN reason r_store          ON sr.sr_reason_sk = r_store.r_reason_sk
LEFT JOIN web_returns wr          ON wr.wr_item_sk = sb.item_sk
LEFT JOIN reason r_web            ON wr.wr_reason_sk = r_web.r_reason_sk
-- Cross‑join a small dimension (a set of years)
CROSS JOIN (VALUES (2021), (2022), (2023)) AS yr(sold_year)
-- Expand an array of metrics per sale
CROSS JOIN UNNEST(
        ARRAY['quantity', 'sales_price', 'net_profit'],
        ARRAY[sb.cs_quantity, sb.cs_sales_price, sb.cs_net_profit]
    ) AS t(metric, metric_value)
ORDER BY sb.cs_net_profit DESC
LIMIT 100
