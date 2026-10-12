WITH aggregated AS (
    SELECT
        d.d_year,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_geography_class,
        ws.web_site_id,
        ws.web_city AS web_city,
        ws.web_state AS web_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(COALESCE(wr.wr_return_amt, 0)) / SUM(ss.ss_ext_sales_price)
            ELSE 0
        END AS return_rate
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk AND s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_geography_class, ws.web_site_id, ws.web_city, ws.web_state
    HAVING SUM(ss.ss_ext_sales_price) > 0
)
SELECT
    a.d_year,
    a.s_store_sk,
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.s_geography_class,
    a.web_site_id,
    a.web_city,
    a.web_state,
    a.total_tickets,
    a.total_quantity_sold,
    a.total_sales_amount,
    a.total_discount_amount,
    a.total_net_profit,
    a.total_return_amount,
    a.total_return_quantity,
    a.return_rate,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank_by_year
FROM aggregated a
ORDER BY a.d_year, profit_rank_by_year
LIMIT 100
