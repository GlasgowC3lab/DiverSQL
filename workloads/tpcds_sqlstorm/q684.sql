WITH sales_union AS (
    SELECT
        CAST('store' AS varchar) AS channel,
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        ss_promo_sk AS promo_sk,
        ss_customer_sk AS cust_sk
    FROM store_sales
    UNION ALL
    SELECT
        CAST('web' AS varchar) AS channel,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_profit,
        CAST(NULL AS integer) AS store_sk,
        ws_warehouse_sk,
        CAST(NULL AS integer) AS call_center_sk,
        ws_web_page_sk,
        ws_promo_sk,
        ws_bill_customer_sk
    FROM web_sales
    UNION ALL
    SELECT
        CAST('catalog' AS varchar) AS channel,
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_net_paid,
        cs_net_profit,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        cs_call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        cs_promo_sk,
        cs_bill_customer_sk
    FROM catalog_sales
),
sales_with_dim AS (
    SELECT
        su.channel,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_color,
        i.i_size,
        COALESCE(p.p_promo_name, 'No_Promo') AS promo_name,
        su.store_sk,
        su.warehouse_sk,
        su.call_center_sk,
        su.web_page_sk,
        su.promo_sk,
        su.cust_sk,
        su.quantity,
        su.net_paid,
        su.net_profit,
        CASE WHEN su.quantity = 0 THEN NULL ELSE su.net_paid / su.quantity END AS avg_price_per_qty,
        CASE WHEN su.quantity = 0 THEN NULL ELSE su.net_profit / su.quantity END AS profit_per_unit,
        CASE 
            WHEN su.net_profit > 0 THEN 'Positive'
            WHEN su.net_profit < 0 THEN 'Negative'
            ELSE 'Zero'
        END AS profit_sign,
        CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_month_seq AS VARCHAR), 2, '0')) AS year_month,
        LENGTH(i.i_item_desc) AS item_desc_len,
        (SELECT SUM(su2.net_profit) FROM sales_union su2 WHERE su2.item_sk = su.item_sk) AS total_item_profit_all_channels,
        (SELECT AVG(su3.net_profit) FROM sales_union su3 WHERE su3.channel = su.channel AND su3.item_sk = su.item_sk) AS avg_channel_item_profit,
        ROW_NUMBER() OVER (PARTITION BY su.channel, d.d_year ORDER BY su.net_profit DESC) AS profit_rank_year,
        RANK() OVER (PARTITION BY su.channel, d.d_year ORDER BY su.net_profit DESC) AS profit_rank_dense_year,
        COUNT(*) OVER (PARTITION BY su.channel, d.d_year) AS total_rows_in_partition,
        SUM(su.net_profit) OVER (PARTITION BY su.channel, d.d_year) AS yearly_profit_total,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name,
        wp.wp_url,
        c.c_preferred_cust_flag,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Other' END AS cust_type,
        CONCAT(su.channel, '_', CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_month_seq AS VARCHAR), 2, '0'))) AS channel_month_label
    FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    LEFT JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON su.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON su.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON su.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c ON su.cust_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
      AND (su.net_profit IS NOT NULL OR su.net_profit = 0)
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag <> 'N')
),
top_items AS (
    SELECT *
    FROM sales_with_dim
    WHERE profit_rank_year <= 5
),
bottom_items AS (
    SELECT *
    FROM sales_with_dim
    WHERE profit_rank_dense_year >= total_rows_in_partition - 4
),
combined AS (
    SELECT
        channel,
        year_month,
        i_item_id,
        i_item_desc,
        i_category,
        i_class,
        i_brand,
        i_color,
        i_size,
        promo_name,
        profit_sign,
        net_profit,
        avg_price_per_qty,
        profit_per_unit,
        total_item_profit_all_channels,
        avg_channel_item_profit,
        profit_rank_year,
        profit_rank_dense_year,
        yearly_profit_total,
        COALESCE(call_center_name, w_warehouse_name, wp_url) AS primary_info,
        cust_type,
        channel_month_label,
        item_desc_len
    FROM top_items
    UNION ALL
    SELECT
        channel,
        year_month,
        i_item_id,
        i_item_desc,
        i_category,
        i_class,
        i_brand,
        i_color,
        i_size,
        promo_name,
        profit_sign,
        net_profit,
        avg_price_per_qty,
        profit_per_unit,
        total_item_profit_all_channels,
        avg_channel_item_profit,
        profit_rank_year,
        profit_rank_dense_year,
        yearly_profit_total,
        COALESCE(call_center_name, w_warehouse_name, wp_url) AS primary_info,
        cust_type,
        channel_month_label,
        item_desc_len
    FROM bottom_items
)
SELECT *
FROM combined
ORDER BY channel, year_month DESC, profit_rank_year
LIMIT 100
