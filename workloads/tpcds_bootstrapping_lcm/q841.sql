WITH sales_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sales.d_date,
        t_sales.t_hour,
        CASE WHEN s.s_closed_date_sk = d_sales.d_date_sk THEN 'Closed' ELSE 'Open' END AS store_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 0
                THEN ROUND(SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price), 4)
            ELSE NULL
        END AS profit_margin,
        COUNT(DISTINCT CASE WHEN t_sales.t_meal_time = 'Lunch' THEN ss.ss_ticket_number END) AS lunch_tickets,
        COUNT(DISTINCT CASE WHEN t_sales.t_meal_time = 'Dinner' THEN ss.ss_ticket_number END) AS dinner_tickets
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sales.d_date_sk
        AND wr.wr_returned_time_sk = t_sales.t_time_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sales.d_date,
        t_sales.t_hour,
        CASE WHEN s.s_closed_date_sk = d_sales.d_date_sk THEN 'Closed' ELSE 'Open' END
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    d_date,
    t_hour,
    store_status,
    tickets_sold,
    total_quantity,
    total_sales_amount,
    total_net_profit,
    avg_sales_price,
    total_return_amount,
    total_return_quantity,
    profit_margin,
    lunch_tickets,
    dinner_tickets,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_summary
ORDER BY total_net_profit DESC
LIMIT 100
