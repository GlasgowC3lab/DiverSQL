WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_order_number AS order_number,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_sales_price AS sales_price,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_net_profit AS net_profit,
           cs.cs_call_center_sk AS call_center_sk,
           cs.cs_warehouse_sk AS warehouse_sk,
           CAST(NULL AS integer) AS store_sk,
           CAST(NULL AS integer) AS web_page_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)

    UNION ALL

    SELECT ss.ss_sold_date_sk,
           ss.ss_ticket_number,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_sales_price,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           ss.ss_store_sk,
           CAST(NULL AS integer),
           'store'
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)

    UNION ALL

    SELECT ws.ws_sold_date_sk,
           ws.ws_order_number,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_sales_price,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           CAST(NULL AS integer),
           ws.ws_warehouse_sk,
           CAST(NULL AS integer),
           ws.ws_web_page_sk,
           'web'
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
),
returns_union AS (
    SELECT cr.cr_returned_date_sk AS return_date_sk,
           cr.cr_order_number AS order_number,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS return_quantity,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss,
           cr.cr_call_center_sk AS call_center_sk,
           cr.cr_warehouse_sk AS warehouse_sk,
           CAST(NULL AS integer) AS store_sk,
           cr.cr_catalog_page_sk AS catalog_page_sk,
           'catalog' AS channel
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)

    UNION ALL

    SELECT sr.sr_returned_date_sk,
           sr.sr_ticket_number,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_net_loss,
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           sr.sr_store_sk,
           CAST(NULL AS integer),
           'store'
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)

    UNION ALL

    SELECT wr.wr_returned_date_sk,
           wr.wr_order_number,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt,
           wr.wr_net_loss,
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           'web'
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)
),
agg AS (
    SELECT
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.sold_date_sk, r.return_date_sk) AS date_sk,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        COALESCE(s.store_sk, r.store_sk) AS store_sk,
        COALESCE(s.warehouse_sk, r.warehouse_sk) AS warehouse_sk,
        SUM(COALESCE(s.quantity, 0)) AS total_quantity_sold,
        SUM(COALESCE(s.ext_sales_price, 0)) AS total_sales_amount,
        SUM(COALESCE(s.net_profit, 0)) AS total_profit,
        SUM(COALESCE(r.return_quantity, 0)) AS total_quantity_returned,
        SUM(COALESCE(r.return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(r.net_loss, 0)) AS total_loss
    FROM sales_union s
    FULL OUTER JOIN returns_union r
        ON s.order_number = r.order_number
        AND s.item_sk = r.item_sk
        AND s.channel = r.channel
    GROUP BY
        COALESCE(s.channel, r.channel),
        COALESCE(s.sold_date_sk, r.return_date_sk),
        COALESCE(s.item_sk, r.item_sk),
        COALESCE(s.store_sk, r.store_sk),
        COALESCE(s.warehouse_sk, r.warehouse_sk)
)
SELECT
    a.channel,
    d.d_year,
    d.d_month_seq,
    a.store_sk,
    COALESCE(s.s_store_name, 'UNKNOWN') AS store_name,
    a.item_sk,
    i.i_product_name AS product_name,
    a.total_quantity_sold,
    a.total_quantity_returned,
    a.total_sales_amount,
    a.total_return_amount,
    (a.total_profit - a.total_loss) AS net_gain,
    ROW_NUMBER() OVER (PARTITION BY a.channel, d.d_year ORDER BY (a.total_profit - a.total_loss) DESC) AS profit_rank,
    CONCAT('Ch-', a.channel, '-Yr', CAST(d.d_year AS VARCHAR), '-Item', CAST(a.item_sk AS VARCHAR)) AS promo_key,
    CASE
        WHEN a.total_quantity_sold = 0 THEN NULL
        ELSE (a.total_quantity_returned * 100.0) / a.total_quantity_sold
    END AS return_rate_pct,
    COALESCE(s.s_state, 'N/A') AS store_state,
    CASE
        WHEN a.channel = 'catalog' THEN (
            SELECT COUNT(DISTINCT cs.cs_bill_customer_sk)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = a.item_sk
              AND cs.cs_sold_date_sk = a.date_sk
        )
        WHEN a.channel = 'store' THEN (
            SELECT COUNT(DISTINCT ss.ss_customer_sk)
            FROM store_sales ss
            WHERE ss.ss_item_sk = a.item_sk
              AND ss.ss_sold_date_sk = a.date_sk
        )
        WHEN a.channel = 'web' THEN (
            SELECT COUNT(DISTINCT ws.ws_bill_customer_sk)
            FROM web_sales ws
            WHERE ws.ws_item_sk = a.item_sk
              AND ws.ws_sold_date_sk = a.date_sk
        )
        ELSE 0
    END AS distinct_customers,
    CONCAT(COALESCE(s.s_city, 'UNKNOWN'), ', ', COALESCE(s.s_state, '')) AS store_location,
    COALESCE(w.w_city, 'N/A') AS warehouse_city
FROM agg a
LEFT JOIN date_dim d ON a.date_sk = d.d_date_sk
LEFT JOIN item i ON a.item_sk = i.i_item_sk
LEFT JOIN store s ON a.store_sk = s.s_store_sk
LEFT JOIN warehouse w ON a.warehouse_sk = w.w_warehouse_sk
WHERE a.total_sales_amount > 10000
  AND (a.total_quantity_sold > 0 OR a.total_quantity_returned > 0)
  AND d.d_year BETWEEN 2000 AND 2006
ORDER BY a.channel, net_gain DESC
LIMIT 100
