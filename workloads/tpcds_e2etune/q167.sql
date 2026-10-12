WITH agg AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        cd_bill.cd_gender AS gender,
        cd_bill.cd_marital_status AS marital_status,
        CASE
            WHEN t_sold.t_hour BETWEEN 0 AND 5 THEN 'Night'
            WHEN t_sold.t_hour BETWEEN 6 AND 11 THEN 'Morning'
            WHEN t_sold.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS time_of_day,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_days
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE cd_bill.cd_credit_rating = 'Good'
      AND d_sold.d_weekend = 'Y'
      AND d_sold.d_year BETWEEN 2000 AND 2002
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        cd_bill.cd_gender,
        cd_bill.cd_marital_status,
        CASE
            WHEN t_sold.t_hour BETWEEN 0 AND 5 THEN 'Night'
            WHEN t_sold.t_hour BETWEEN 6 AND 11 THEN 'Morning'
            WHEN t_sold.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END
    HAVING SUM(ws.ws_ext_sales_price) > 100000
)
SELECT
    d_year,
    d_month_seq,
    gender,
    marital_status,
    time_of_day,
    total_sales,
    total_profit,
    avg_quantity,
    profit_margin,
    avg_shipping_days,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
