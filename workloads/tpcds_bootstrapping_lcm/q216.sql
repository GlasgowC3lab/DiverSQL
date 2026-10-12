SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sold.d_year AS sold_year,
    sold.d_month_seq AS sold_month,
    site.web_name,
    site.web_city,
    site.web_state,
    site_open.d_year AS site_open_year,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(*) AS sales_count
FROM web_sales ws
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN date_dim sold
    ON ws.ws_sold_date_sk = sold.d_date_sk
JOIN date_dim ship
    ON ws.ws_ship_date_sk = ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ship.d_date_sk
JOIN date_dim site_open
    ON site.web_open_date_sk = site_open.d_date_sk
WHERE sold.d_year = 2020
  AND site_open.d_year <= sold.d_year
  AND s.s_state = 'CA'
  AND cd.cd_credit_rating = 'Excellent'
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sold.d_year,
    sold.d_month_seq,
    site.web_name,
    site.web_city,
    site.web_state,
    site_open.d_year,
    s.s_city,
    s.s_state,
    s.s_floor_space
ORDER BY total_net_profit DESC
LIMIT 100
