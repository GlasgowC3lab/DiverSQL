WITH unified_sales AS (
    SELECT
        CAST('store' AS varchar) AS sales_channel,
        ss_sold_date_sk AS sold_date_sk,
        ss_sold_time_sk AS sold_time_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        ss_cdemo_sk AS cdemo_sk,
        ss_hdemo_sk AS hdemo_sk,
        ss_addr_sk AS addr_sk,
        ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        CAST(NULL AS integer) AS web_page_sk,
        CAST(NULL AS integer) AS web_site_sk,
        ss_promo_sk AS promo_sk,
        ss_ticket_number AS order_number,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_ext_discount_amt AS ext_discount_amt,
        ss_ext_sales_price AS ext_sales_price
    FROM store_sales
    UNION ALL
    SELECT
        CAST('catalog' AS varchar) AS sales_channel,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_item_sk,
        cs_bill_customer_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        CAST(NULL AS integer),
        cs_call_center_sk,
        cs_catalog_page_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        cs_promo_sk,
        cs_order_number,
        cs_quantity,
        cs_net_paid,
        cs_net_profit,
        cs_ext_discount_amt,
        cs_ext_sales_price
    FROM catalog_sales
    UNION ALL
    SELECT
        CAST('web' AS varchar) AS sales_channel,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws_web_page_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ws_net_profit,
        ws_ext_discount_amt,
        ws_ext_sales_price
    FROM web_sales
),
aggregated AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        COALESCE(s.s_state, cc.cc_state, ws.web_state) AS region_state,
        us.sales_channel,
        SUM(us.ext_sales_price) AS total_sales,
        SUM(us.net_profit) AS total_profit,
        SUM(us.ext_discount_amt) AS total_discount,
        SUM(us.quantity) AS total_quantity,
        COUNT(DISTINCT us.order_number) AS order_cnt,
        COUNT(DISTINCT us.customer_sk) AS distinct_customers,
        CASE WHEN SUM(us.ext_sales_price) = 0 THEN 0
             ELSE SUM(us.ext_discount_amt) / SUM(us.ext_sales_price) END AS avg_discount_rate
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_site ws ON us.web_site_sk = ws.web_site_sk
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category,
        COALESCE(s.s_state, cc.cc_state, ws.web_state),
        us.sales_channel
)
SELECT
    d_year,
    d_moy,
    i_category,
    region_state,
    sales_channel,
    total_sales,
    total_profit,
    total_discount,
    total_quantity,
    order_cnt,
    distinct_customers,
    avg_discount_rate,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_moy, sales_channel ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY i_category ORDER BY d_year, d_moy ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3mo_moving_avg
FROM aggregated
ORDER BY d_year, d_moy, sales_channel, profit_rank
