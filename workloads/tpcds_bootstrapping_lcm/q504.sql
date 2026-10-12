WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_addr_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_store_sk, ss_addr_sk, ss_sold_date_sk
),
returns_agg AS (
    SELECT
        wr_refunded_addr_sk   AS refunded_addr_sk,
        wr_returning_addr_sk  AS returning_addr_sk,
        wr_returned_date_sk   AS returned_date_sk,
        SUM(wr_return_amt)    AS total_return_amount,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_net_loss)      AS total_net_loss
    FROM web_returns
    GROUP BY wr_refunded_addr_sk, wr_returning_addr_sk, wr_returned_date_sk
)
SELECT
    ca_sales.ca_address_id,
    ca_sales.ca_city          AS sales_city,
    ca_sales.ca_state         AS sales_state,
    ca_sales.ca_zip           AS sales_zip,
    ca_refunded.ca_city       AS refunded_city,
    ca_refunded.ca_state      AS refunded_state,
    ca_returning.ca_city      AS returning_city,
    ca_returning.ca_state     AS returning_state,
    s.s_store_name,
    s.s_state                 AS store_state,
    d_sale.d_date             AS sale_date,
    d_return.d_date           AS return_date,
    d_closed.d_date           AS store_closed_date,
    COALESCE(sa.total_sales, 0)            AS total_sales,
    COALESCE(ra.total_return_amount, 0)    AS total_return_amount,
    COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0) AS net_contribution,
    RANK() OVER (ORDER BY (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amount, 0)) DESC) AS revenue_rank
FROM sales_agg sa
JOIN customer_address ca_sales
    ON ca_sales.ca_address_sk = sa.ss_addr_sk
JOIN store s
    ON s.s_store_sk = sa.ss_store_sk
JOIN date_dim d_sale
    ON d_sale.d_date_sk = sa.ss_sold_date_sk
LEFT JOIN returns_agg ra
    ON ra.refunded_addr_sk = ca_sales.ca_address_sk
   AND ra.returned_date_sk = d_sale.d_date_sk
LEFT JOIN customer_address ca_refunded
    ON ca_refunded.ca_address_sk = ra.refunded_addr_sk
LEFT JOIN customer_address ca_returning
    ON ca_returning.ca_address_sk = ra.returning_addr_sk
LEFT JOIN date_dim d_return
    ON d_return.d_date_sk = ra.returned_date_sk
JOIN date_dim d_closed
    ON d_closed.d_date_sk = s.s_closed_date_sk
ORDER BY net_contribution DESC
LIMIT 100
