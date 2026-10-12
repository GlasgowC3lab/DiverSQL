WITH agg AS (
    SELECT
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        ca_bill.ca_city AS billing_city,
        ca_returning.ca_state AS returning_state,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        COUNT(wr.wr_return_quantity) AS num_returns
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    GROUP BY
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        ca_bill.ca_city,
        ca_returning.ca_state
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    billing_city,
    returning_state,
    total_sales,
    total_ext_sales,
    total_profit,
    total_return_amount,
    num_orders,
    num_returns,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
