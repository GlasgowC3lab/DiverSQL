WITH
sales_agg AS (
    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           SUM(cs.cs_quantity) AS sales_qty,
           SUM(cs.cs_sales_price * cs.cs_quantity) AS sales_amount,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
           cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_bill_customer_sk
    UNION ALL
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           SUM(ss.ss_quantity) AS sales_qty,
           SUM(ss.ss_sales_price * ss.ss_quantity) AS sales_amount,
           COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
           ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_customer_sk
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           SUM(ws.ws_quantity) AS sales_qty,
           SUM(ws.ws_sales_price * ws.ws_quantity) AS sales_amount,
           COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
           ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_bill_customer_sk
),
returns_agg AS (
    SELECT 'catalog' AS channel,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           SUM(cr.cr_return_quantity) AS return_qty,
           SUM(cr.cr_return_amount) AS return_amount,
           cr.cr_returning_customer_sk AS cust_sk
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk, cr.cr_returning_customer_sk
    UNION ALL
    SELECT 'store' AS channel,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           SUM(sr.sr_return_quantity) AS return_qty,
           SUM(sr.sr_return_amt) AS return_amount,
           sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk, sr.sr_customer_sk
    UNION ALL
    SELECT 'web' AS channel,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_item_sk AS item_sk,
           SUM(wr.wr_return_quantity) AS return_qty,
           SUM(wr.wr_return_amt) AS return_amount,
           wr.wr_returning_customer_sk AS cust_sk
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk, wr.wr_returning_customer_sk
),
item_latest_price AS (
    SELECT i_item_sk,
           i_current_price,
           i_item_id,
           ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_rec_start_date DESC) AS rn
    FROM item
    WHERE i_rec_start_date <= DATE '2024-10-01'
      AND (i_rec_end_date > DATE '2024-10-01' OR i_rec_end_date IS NULL)
),
sales_returns_combined AS (
    SELECT
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        s.sales_qty,
        s.sales_amount,
        s.order_cnt,
        r.return_qty,
        r.return_amount,
        s.cust_sk AS sales_cust_sk,
        r.cust_sk AS return_cust_sk
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.channel = r.channel
     AND s.date_sk = r.date_sk
     AND s.item_sk = r.item_sk
)
SELECT
    srt.channel,
    srt.date_sk,
    (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = srt.date_sk) AS sale_date,
    srt.item_sk,
    i.i_item_id,
    ip.i_current_price,
    srt.sales_qty,
    srt.return_qty,
    srt.sales_amount,
    srt.return_amount,
    CASE 
        WHEN COALESCE(srt.return_qty, 0) = 0 THEN NULL 
        ELSE srt.sales_qty / NULLIF(srt.return_qty, 0) 
    END AS sales_return_qty_ratio,
    CASE 
        WHEN COALESCE(srt.return_amount, 0) = 0 THEN NULL 
        ELSE srt.sales_amount / NULLIF(srt.return_amount, 0) 
    END AS sales_return_amount_ratio,
    CASE 
        WHEN srt.sales_qty IS NOT NULL AND srt.return_qty IS NULL THEN 'SaleOnly'
        WHEN srt.sales_qty IS NULL AND srt.return_qty IS NOT NULL THEN 'ReturnOnly'
        WHEN srt.sales_qty IS NOT NULL AND srt.return_qty IS NOT NULL THEN 'Both'
        ELSE 'None'
    END AS activity_type,
    CONCAT(srt.channel, '-', i.i_item_id) AS channel_item_code,
    SUBSTRING(i.i_product_name, 1, 10) AS product_name_prefix,
    COALESCE(srt.sales_qty, 0) - COALESCE(srt.return_qty, 0) AS net_quantity,
    COALESCE(srt.sales_amount, 0) - COALESCE(srt.return_amount, 0) AS net_amount,
    la.avg_qty_to_date,
    (SELECT MAX(r2.return_qty) FROM returns_agg r2 WHERE r2.item_sk = srt.item_sk) AS max_return_qty_overall,
    SUM(COALESCE(srt.sales_amount, 0)) OVER (PARTITION BY srt.channel ORDER BY srt.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_amount,
    ROW_NUMBER() OVER (PARTITION BY srt.channel ORDER BY COALESCE(srt.sales_amount, 0) DESC) AS rank_by_sales_amount,
    CASE 
        WHEN c.c_preferred_cust_flag = 'Y' THEN CONCAT('Preferred_', COALESCE(c.c_customer_id, 'UNKNOWN'))
        ELSE COALESCE(c.c_customer_id, 'NONPREFER')
    END AS cust_flagged_id,
    CAST(srt.sales_qty AS VARCHAR) AS sales_qty_str
FROM sales_returns_combined srt
LEFT JOIN item_latest_price ip ON ip.i_item_sk = srt.item_sk AND ip.rn = 1
LEFT JOIN item i ON i.i_item_sk = srt.item_sk
LEFT JOIN LATERAL (
    SELECT AVG(x.sales_qty) AS avg_qty_to_date
    FROM sales_agg x
    WHERE x.item_sk = srt.item_sk
      AND x.date_sk <= srt.date_sk
) la ON TRUE
LEFT JOIN customer c ON c.c_customer_sk = COALESCE(srt.sales_cust_sk, srt.return_cust_sk)
WHERE
    ( (srt.sales_qty > 0 AND srt.return_qty IS NULL)
      OR (srt.sales_qty IS NULL AND srt.return_qty > 0)
      OR (srt.sales_qty IS NOT NULL AND srt.return_qty IS NOT NULL AND ABS(srt.sales_qty - srt.return_qty) < 5)
    )
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
    AND (LOWER(c.c_email_address) LIKE '%@example.com%' OR c.c_email_address IS NULL)
ORDER BY srt.channel, srt.date_sk DESC
LIMIT 100
