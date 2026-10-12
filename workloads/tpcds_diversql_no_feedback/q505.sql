WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sales.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
        AND wr.wr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
    LEFT JOIN customer_address ca_wr_ret ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    WHERE
        d_sales.d_year = 2002
        AND s.s_state = 'CA'
        AND ws.web_tax_percentage > 0.07
        AND d_sales.d_holiday = 'N'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sales.d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    total_sales,
    total_profit,
    store_return_count,
    web_return_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 20
