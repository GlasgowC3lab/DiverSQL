WITH ship_daily AS (
    SELECT
        cs.cs_ship_date_sk,
        d.d_date,
        d.d_year,
        d.d_week_seq,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        SUM(cs.cs_wholesale_cost * cs.cs_quantity) AS total_wholesale_cost,
        SUM(cs.cs_ext_ship_cost) / NULLIF(SUM(cs.cs_wholesale_cost * cs.cs_quantity), 0) AS ship_to_wholesale_ratio,
        AVG(t.t_hour) AS avg_sale_hour
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY cs.cs_ship_date_sk, d.d_date, d.d_year, d.d_week_seq
), ship_with_lag AS (
    SELECT
        sd.*,
        LAG(sd.total_ship_cost) OVER (PARTITION BY sd.d_year ORDER BY sd.d_date) AS prev_day_ship_cost,
        LEAD(sd.total_ship_cost) OVER (PARTITION BY sd.d_year ORDER BY sd.d_date) AS next_day_ship_cost,
        CASE 
            WHEN sd.ship_to_wholesale_ratio > 0.1 THEN 'High Ship Cost'
            ELSE 'Normal Ship Cost'
        END AS ship_cost_category,
        CASE 
            WHEN sd.avg_sale_hour >= 15 THEN 'Evening Sales'
            ELSE 'Daytime Sales'
        END AS sale_hour_category
    FROM ship_daily sd
)
SELECT
    swl.d_date,
    swl.d_year,
    swl.d_week_seq,
    swl.total_ship_cost,
    swl.total_wholesale_cost,
    swl.ship_to_wholesale_ratio,
    swl.prev_day_ship_cost,
    swl.next_day_ship_cost,
    swl.ship_cost_category,
    swl.sale_hour_category,
    ws.web_name
FROM ship_with_lag swl
LEFT JOIN web_site ws
  ON swl.cs_ship_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
ORDER BY swl.d_date
