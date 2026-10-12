WITH sales_in_catalog AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk
    FROM store_sales ss
    JOIN catalog_page cp
        ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
        AND cp.cp_catalog_page_number = 2
),
returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_amt
    FROM store_returns sr
),
aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        date_format(date_add('day', ss.ss_sold_date_sk, date '1970-01-01'), '%Y-%m') AS year_month,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COALESCE(SUM(r.sr_return_amt), 0) AS total_return_amt
    FROM sales_in_catalog ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN returns r
        ON ss.ss_ticket_number = r.sr_ticket_number
        AND ss.ss_item_sk = r.sr_item_sk
        AND ss.ss_store_sk = r.sr_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        date_format(date_add('day', ss.ss_sold_date_sk, date '1970-01-01'), '%Y-%m')
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.year_month,
    a.total_net_paid,
    a.total_net_paid_inc_tax,
    a.total_net_profit,
    a.distinct_customers,
    a.avg_discount,
    a.total_return_amt,
    CASE WHEN a.total_net_paid = 0 THEN 0
         ELSE a.total_return_amt / a.total_net_paid END AS return_rate,
    RANK() OVER (PARTITION BY a.year_month ORDER BY a.total_net_paid DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 100
