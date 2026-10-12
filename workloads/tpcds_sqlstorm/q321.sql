WITH date_filtered AS (
    SELECT d_date_sk,
           d_year
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
),
item_filtered AS (
    SELECT i_item_sk,
           i_item_id,
           i_product_name,
           i_category,
           i_brand
    FROM item
    WHERE i_category IN ('Electronics', 'Sports', 'Books')
),
cust_demo_filtered AS (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_gender = 'F' AND cd_education_status = 'College'
),
catalog_sales_agg AS (
    SELECT d.d_year,
           'catalog' AS channel,
           i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item_filtered i ON cs.cs_item_sk = i.i_item_sk
    JOIN cust_demo_filtered cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY d.d_year,
             i.i_item_sk,
             i.i_item_id,
             i.i_product_name
),
store_sales_agg AS (
    SELECT d.d_year,
           'store' AS channel,
           i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item_filtered i ON ss.ss_item_sk = i.i_item_sk
    JOIN cust_demo_filtered cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY d.d_year,
             i.i_item_sk,
             i.i_item_id,
             i.i_product_name
),
web_sales_agg AS (
    SELECT d.d_year,
           'web' AS channel,
           i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item_filtered i ON ws.ws_item_sk = i.i_item_sk
    JOIN cust_demo_filtered cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY d.d_year,
             i.i_item_sk,
             i.i_item_id,
             i.i_product_name
),
combined_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
ranked_sales AS (
    SELECT d_year,
           channel,
           i_item_sk,
           i_item_id,
           i_product_name,
           total_quantity,
           total_sales,
           total_profit,
           order_count,
           ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_profit DESC) AS profit_rank,
           NTILE(10) OVER (PARTITION BY d_year, channel ORDER BY total_profit) AS profit_decile
    FROM combined_sales
)
SELECT d_year,
       channel,
       i_item_id,
       i_product_name,
       total_quantity,
       total_sales,
       total_profit,
       order_count,
       profit_rank,
       profit_decile
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY d_year,
         channel,
         profit_rank
