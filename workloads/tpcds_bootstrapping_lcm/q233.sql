WITH sales_agg AS (
    SELECT
        ds.d_year,
        s.s_store_name,
        s.s_city,
        ca_bill.ca_city AS bill_city,
        ca_returning.ca_city AS return_city,
        ca_refunded.ca_state AS refunded_state,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_sales_qty,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(wr.wr_net_loss) AS total_return_loss,
        (SUM(cs.cs_net_profit) - SUM(wr.wr_net_loss)) AS net_profit_after_returns
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = ds.d_date_sk
    JOIN store s ON s.s_closed_date_sk = ds.d_date_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    GROUP BY
        ds.d_year,
        s.s_store_name,
        s.s_city,
        ca_bill.ca_city,
        ca_returning.ca_city,
        ca_refunded.ca_state
)
SELECT
    d_year,
    s_store_name,
    s_city,
    bill_city,
    return_city,
    refunded_state,
    total_sales_amount,
    total_sales_qty,
    avg_discount,
    total_return_qty,
    total_return_amount,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns,
    RANK() OVER (ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM sales_agg
ORDER BY net_profit_after_returns DESC
LIMIT 100
