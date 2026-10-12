WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        ds.d_year,
        ds.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount_inc_tax,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
        COUNT(DISTINCT ca_refunded.ca_city) AS distinct_refunded_cities,
        COUNT(DISTINCT ca_returning.ca_city) AS distinct_returning_customer_cities,
        cl.d_date AS store_closed_date,
        CASE WHEN cl.d_date IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status
    FROM store_sales ss
    JOIN date_dim ds
        ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_sales
        ON ss.ss_addr_sk = ca_sales.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = ds.d_date_sk
    LEFT JOIN date_dim cl
        ON s.s_closed_date_sk = cl.d_date_sk
    LEFT JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE ds.d_year BETWEEN 2020 AND 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        ds.d_year,
        ds.d_month_seq,
        cl.d_date
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales_amount DESC) AS sales_rank_within_month
FROM sales_agg
ORDER BY d_year, d_month_seq, total_sales_amount DESC
LIMIT 200
