WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           'catalog' AS channel,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_sold_time_sk AS time_sk
    FROM catalog_sales cs

    UNION ALL

    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           'store',
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt,
           ss.ss_sold_time_sk
    FROM store_sales ss

    UNION ALL

    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           'web',
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           ws.ws_sold_time_sk
    FROM web_sales ws
),
sales_with_dates AS (
    SELECT us.*,
           d.d_year,
           d.d_month_seq,
           d.d_week_seq,
           d.d_date,
           COALESCE(d.d_holiday, 'N') AS holiday_flag
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
),
ranked_sales AS (
    SELECT swd.*,
           ROW_NUMBER() OVER (PARTITION BY swd.item_sk, swd.d_year ORDER BY swd.net_paid DESC) AS rn_yearly_top,
           AVG(swd.net_paid) OVER (PARTITION BY swd.item_sk ORDER BY swd.sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
           CASE 
               WHEN swd.net_profit < 0 THEN 'loss'
               WHEN swd.net_profit = 0 THEN 'break-even'
               ELSE 'profit'
           END AS profit_category,
           CASE WHEN swd.discount_amt IS NULL THEN 'NoDiscount' ELSE 'Discounted' END AS discount_flag,
           CONCAT(swd.channel, '-', CAST(swd.item_sk AS VARCHAR)) AS item_channel_key,
           CASE WHEN NULLIF(swd.net_paid, 0) IS NULL THEN NULL ELSE swd.net_profit / NULLIF(swd.net_paid, 0) END AS gross_margin_ratio,
           SUM(swd.net_paid) OVER (PARTITION BY swd.channel, swd.d_year, swd.d_month_seq) AS monthly_channel_total,
           MIN(swd.net_paid) OVER (PARTITION BY swd.item_sk) AS min_item_net_paid,
           MAX(swd.net_paid) OVER (PARTITION BY swd.item_sk) AS max_item_net_paid,
           AVG(swd.discount_amt) OVER (PARTITION BY swd.channel) AS avg_discount_per_channel,
           REGEXP_REPLACE(CONCAT(swd.channel, '-', CAST(swd.item_sk AS VARCHAR)), '\\D+', '') AS numeric_key_part,
           TRY_CAST(REGEXP_REPLACE(CONCAT(swd.channel, '-', CAST(swd.item_sk AS VARCHAR)), '\\D+', '') AS INTEGER) AS numeric_key_as_int
    FROM sales_with_dates swd
),
high_value_sales AS (
    SELECT *
    FROM ranked_sales
    WHERE net_paid >= 1000
      AND profit_category = 'profit'
      AND rn_yearly_top <= 5
),
low_value_sales AS (
    SELECT *
    FROM ranked_sales
    WHERE net_paid < 1000
      AND profit_category <> 'loss'
      AND moving_avg_7d IS NOT NULL
),
combined_sales AS (
    SELECT * FROM high_value_sales
    UNION ALL
    SELECT * FROM low_value_sales
),
returns_union AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           'store' AS channel,
           sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr

    UNION ALL

    SELECT wr.wr_refunded_customer_sk AS customer_sk,
           'web' AS channel,
           wr.wr_returned_date_sk AS returned_date_sk,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr

    UNION ALL

    SELECT cr.cr_refunded_customer_sk AS customer_sk,
           'catalog' AS channel,
           cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
),
customers_with_returns AS (
    SELECT DISTINCT ru.customer_sk
    FROM returns_union ru
    WHERE ru.net_loss > 0
),
store_web_return_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS customer_sk FROM store_returns sr
    INTERSECT
    SELECT DISTINCT wr.wr_refunded_customer_sk AS customer_sk FROM web_returns wr
),
customer_last_purchase AS (
    SELECT us.customer_sk,
           MAX(us.sold_date_sk) AS last_purchase_date_sk
    FROM unified_sales us
    GROUP BY us.customer_sk
),
customer_last_purchase_date AS (
    SELECT clp.customer_sk,
           d.d_date AS last_purchase_date,
           d.d_year,
           d.d_month_seq
    FROM customer_last_purchase clp
    LEFT JOIN date_dim d ON clp.last_purchase_date_sk = d.d_date_sk
),
final_combined AS (
    SELECT cs.*,
           CASE WHEN cwr.customer_sk IS NOT NULL THEN 'HasReturn' ELSE 'NoReturn' END AS return_flag,
           rp.last_purchase_date,
           CASE WHEN swrc.customer_sk IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_store_and_web_return_flag,
           CASE 
               WHEN EXISTS (SELECT 1 FROM store_returns sr2 
                            WHERE sr2.sr_customer_sk = cs.customer_sk 
                              AND sr2.sr_returned_date_sk > cs.sold_date_sk) THEN 1 
               ELSE 0 
           END AS recent_store_return_flag,
           CASE 
               WHEN EXISTS (SELECT 1 FROM web_returns wr2 
                            WHERE wr2.wr_refunded_customer_sk = cs.customer_sk 
                              AND wr2.wr_returned_date_sk > cs.sold_date_sk) THEN 1 
               ELSE 0 
           END AS recent_web_return_flag,
           CASE 
               WHEN cs.gross_margin_ratio IS NULL THEN 'Undefined'
               WHEN cs.gross_margin_ratio > 0.2 THEN 'High'
               WHEN cs.gross_margin_ratio > 0.1 THEN 'Medium'
               ELSE 'Low' 
           END AS gross_margin_category,
           CONCAT_WS('_', cs.channel, cs.item_channel_key) AS composite_key,
           CASE WHEN cs.discount_flag = 'NoDiscount' THEN NULL ELSE cs.discount_flag END AS discount_flag_normalized,
           (SELECT COUNT(DISTINCT p.p_promo_id) FROM promotion p WHERE p.p_item_sk = cs.item_sk) AS promo_count_for_item,
           (SELECT MAX(r2.net_loss) FROM returns_union r2 WHERE r2.customer_sk = cs.customer_sk) AS max_return_loss
    FROM combined_sales cs
    LEFT JOIN customers_with_returns cwr ON cs.customer_sk = cwr.customer_sk
    LEFT JOIN customer_last_purchase_date rp ON cs.customer_sk = rp.customer_sk
    LEFT JOIN store_web_return_customers swrc ON cs.customer_sk = swrc.customer_sk
)
SELECT *
FROM final_combined
WHERE (return_flag = 'HasReturn' AND net_profit > 0)
   OR (return_flag = 'NoReturn' AND net_profit < 0)
ORDER BY d_year DESC, d_month_seq, net_paid DESC
LIMIT 100
