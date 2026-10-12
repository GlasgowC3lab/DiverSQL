WITH return_aggregates AS (
    SELECT
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        wr.wr_returned_date_sk AS d_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_hdemo_sk, wr.wr_returned_date_sk
)
SELECT
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_quarter_name,
    hd.hd_buy_potential,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COALESCE(SUM(ra.total_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(ra.total_return_qty), 0) AS total_return_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_quantity) AS avg_quantity_per_sale,
    CASE
        WHEN d_close.d_date IS NULL THEN 'Open'
        ELSE CONCAT('Closed on ', CAST(d_close.d_date AS VARCHAR))
    END AS store_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank_within_store
FROM date_dim d_sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN return_aggregates ra
    ON ra.hd_demo_sk = hd.hd_demo_sk
   AND ra.d_date_sk = d_sales.d_date_sk
JOIN date_dim d_close
    ON s.s_closed_date_sk = d_close.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_country = 'United States'
  AND hd.hd_buy_potential IN ('High', 'Medium')
GROUP BY
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_quarter_name,
    hd.hd_buy_potential,
    d_close.d_date
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
