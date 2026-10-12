WITH sales_store AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS location_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_ext_sales_price AS sales_price,
        ss.ss_ext_tax AS tax_amount,
        ss.ss_coupon_amt AS coupon_amt,
        COALESCE(st.s_city, '') || ', ' || COALESCE(st.s_state, '') AS location_desc,
        CASE WHEN ss.ss_ext_sales_price > 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_sales_price ELSE 0 END AS discount_pct,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount
    FROM store_sales ss
    LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
), sales_catalog AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_warehouse_sk AS location_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_ext_sales_price AS sales_price,
        cs.cs_ext_tax AS tax_amount,
        cs.cs_coupon_amt AS coupon_amt,
        COALESCE(w.w_city, '') || ', ' || COALESCE(w.w_state, '') AS location_desc,
        CASE WHEN cs.cs_ext_sales_price > 0 THEN cs.cs_ext_discount_amt / cs.cs_ext_sales_price ELSE 0 END AS discount_pct,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount
    FROM catalog_sales cs
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
), sales_web AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_web_page_sk AS location_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_ext_sales_price AS sales_price,
        ws.ws_ext_tax AS tax_amount,
        ws.ws_coupon_amt AS coupon_amt,
        COALESCE(wp.wp_url, '') AS location_desc,
        CASE WHEN ws.ws_ext_sales_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_sales_price ELSE 0 END AS discount_pct,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
), all_sales AS (
    SELECT * FROM sales_store
    UNION ALL
    SELECT * FROM sales_catalog
    UNION ALL
    SELECT * FROM sales_web
), sales_with_customer_avg AS (
    SELECT
        asd.*,
        (
            SELECT AVG(inner_s.discount_amt)
            FROM all_sales inner_s
            WHERE inner_s.customer_sk = asd.customer_sk
              AND inner_s.date_sk <= asd.date_sk
        ) AS cust_avg_discount
    FROM all_sales asd
), monthly_agg_base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        asd.channel,
        SUM(asd.net_paid) AS total_net_paid,
        SUM(asd.net_profit) AS total_net_profit,
        SUM(COALESCE(asd.return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(asd.return_quantity, 0)) AS total_return_quantity,
        AVG(asd.discount_pct) AS avg_discount_pct,
        AVG(asd.cust_avg_discount) AS avg_customer_discount,
        COUNT(DISTINCT asd.item_sk) AS distinct_items_sold,
        COUNT(DISTINCT asd.customer_sk) AS distinct_customers,
        SUM(asd.discount_amt) AS total_discount_amount,
        SUM(asd.sales_price) AS total_sales_price,
        SUM(asd.tax_amount) AS total_tax,
        SUM(asd.coupon_amt) AS total_coupon_amount
    FROM sales_with_customer_avg asd
    JOIN date_dim d ON asd.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, asd.channel
), monthly_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank,
        total_net_profit / NULLIF(total_net_paid, 0) AS profit_margin
    FROM monthly_agg_base
), top_items_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        asd.channel,
        asd.item_sk,
        SUM(asd.net_profit) AS item_total_profit
    FROM sales_with_customer_avg asd
    JOIN date_dim d ON asd.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, asd.channel, asd.item_sk
    HAVING SUM(asd.net_profit) > 0
), top_items AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY item_total_profit DESC) AS item_rank
    FROM top_items_raw
), top_three_items AS (
    SELECT *
    FROM top_items
    WHERE item_rank <= 3
), cross_channel_items AS (
    SELECT d.d_year, d.d_month_seq, asd.item_sk
    FROM sales_with_customer_avg asd
    JOIN date_dim d ON asd.date_sk = d.d_date_sk
    WHERE asd.channel = 'store'
    INTERSECT
    SELECT d.d_year, d.d_month_seq, asd.item_sk
    FROM sales_with_customer_avg asd
    JOIN date_dim d ON asd.date_sk = d.d_date_sk
    WHERE asd.channel = 'web'
)
SELECT
    ma.d_year,
    ma.d_month_seq,
    ma.channel,
    ma.total_net_paid,
    ma.total_net_profit,
    ma.profit_margin,
    ma.total_return_amount,
    ma.total_return_quantity,
    ma.avg_discount_pct,
    ma.avg_customer_discount,
    ma.distinct_items_sold,
    ma.distinct_customers,
    ma.total_discount_amount,
    ma.total_sales_price,
    ma.total_tax,
    ma.total_coupon_amount,
    ma.profit_rank,
    CASE WHEN EXISTS (
        SELECT 1
        FROM cross_channel_items cci
        WHERE cci.d_year = ma.d_year
          AND cci.d_month_seq = ma.d_month_seq
    ) THEN 1 ELSE 0 END AS sold_in_multiple_channels,
    ti.item_sk AS top_item_sk,
    ti.item_total_profit AS top_item_profit,
    ti.item_rank AS top_item_rank,
    CASE WHEN ma.total_return_amount > ma.total_net_paid THEN 'Loss' ELSE 'Gain' END AS overall_status
FROM monthly_agg ma
LEFT JOIN top_three_items ti
    ON ma.d_year = ti.d_year
   AND ma.d_month_seq = ti.d_month_seq
   AND ma.channel = ti.channel
ORDER BY ma.d_year, ma.d_month_seq, ma.channel, ma.profit_rank
