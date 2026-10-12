SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wsite.web_site_id,
    wsite.web_name,
    d_sold.d_year AS sales_year,
    d_sold.d_quarter_name,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    ROUND(
        COALESCE(SUM(ss.ss_ext_discount_amt), 0) / NULLIF(SUM(ss.ss_ext_list_price), 0),
        4
    ) AS store_discount_rate,
    ROUND(
        COALESCE(SUM(ws.ws_ext_discount_amt), 0) / NULLIF(SUM(ws.ws_ext_list_price), 0),
        4
    ) AS web_discount_rate,
    CASE
        WHEN (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)) = 0 THEN 0
        ELSE ROUND(
            (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) /
            (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)),
            4
        )
    END AS overall_profit_margin,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    d_closed.d_year AS store_closed_year,
    d_open.d_year AS web_open_year,
    d_close.d_year AS web_close_year
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
  ON wsite.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
  ON wsite.web_close_date_sk = d_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
  AND s.s_state = 'CA'
  AND d_open.d_year <= d_sold.d_year
  AND d_close.d_year >= d_sold.d_year
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wsite.web_site_id,
    wsite.web_name,
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_closed.d_year,
    d_open.d_year,
    d_close.d_year
ORDER BY overall_profit_margin DESC, total_store_sales DESC, total_web_sales DESC
LIMIT 100
