WITH store_sales_base AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_ticket_number AS ticket_number,
        CONCAT(s.s_state, '-', s.s_city) AS store_loc,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_ext_discount_amt AS ext_discount_amt,
        ss.ss_coupon_amt AS coupon_amt,
        ss.ss_ext_tax AS ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn_latest,
        CASE WHEN EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = ss.ss_item_sk AND sr.sr_returned_date_sk = ss.ss_sold_date_sk) THEN 'Returned' ELSE 'NotReturned' END AS return_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
),
catalog_sales_base AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_order_number AS ticket_number,
        CONCAT(cc.cc_state, '-', cc.cc_city) AS store_loc,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_coupon_amt AS coupon_amt,
        cs.cs_ext_tax AS ext_tax,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY cs.cs_sold_date_sk DESC) AS rn_latest,
        NULL AS return_flag
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
),
web_sales_base AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_order_number AS ticket_number,
        CONCAT(wp.wp_type, '-', CAST(ws.ws_web_page_sk AS varchar)) AS store_loc,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_ext_discount_amt AS ext_discount_amt,
        ws.ws_coupon_amt AS coupon_amt,
        ws.ws_ext_tax AS ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn_latest,
        NULL AS return_flag
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
),
combined_sales AS (
    SELECT * FROM store_sales_base
    UNION ALL
    SELECT * FROM catalog_sales_base
    UNION ALL
    SELECT * FROM web_sales_base
),
base_aggregated AS (
    SELECT
        store_loc,
        d_year,
        d_month_seq,
        i_category,
        i_class,
        i_brand,
        promo_name,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid,
        AVG(ext_sales_price) AS avg_ext_sales_price,
        SUM(CASE WHEN profit_flag = 'Profit' THEN net_profit ELSE 0 END) AS profit_sum,
        COUNT(DISTINCT ticket_number) AS distinct_tickets,
        SUM(CASE WHEN return_flag = 'Returned' THEN net_profit ELSE 0 END) AS returned_profit,
        MAX(CASE WHEN rn_latest = 1 THEN ext_sales_price END) AS most_recent_ext_sales_price,
        COALESCE(NULLIF(promo_name, 'No Promo'), 'None') AS effective_promo_name,
        CONCAT(store_loc, ':', CAST(d_month_seq AS varchar), '-', CAST(d_year AS varchar)) AS period_label
    FROM combined_sales
    GROUP BY GROUPING SETS (
        (store_loc, d_year, d_month_seq, i_category, i_class, i_brand, promo_name),
        (store_loc, d_year, d_month_seq, i_category),
        (store_loc, d_year)
    )
    HAVING SUM(net_profit) > 0
)
SELECT
    store_loc,
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    promo_name,
    total_net_profit,
    total_net_paid,
    avg_ext_sales_price,
    profit_sum,
    distinct_tickets,
    returned_profit,
    most_recent_ext_sales_price,
    effective_promo_name,
    period_label,
    ROW_NUMBER() OVER (PARTITION BY store_loc ORDER BY total_net_profit DESC) AS rank_by_profit
FROM base_aggregated
ORDER BY total_net_profit DESC
LIMIT 100
