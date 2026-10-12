WITH sales_no_return AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
)
SELECT
    s.s_store_name,
    dd_order.d_year,
    SUM(cs.cs_net_profit)                         AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number)            AS orders_cnt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS store_profit_rank
FROM sales_no_return sr
JOIN catalog_sales cs               ON cs.cs_order_number = sr.cs_order_number                               -- join 1
JOIN date_dim dd_order               ON cs.cs_sold_date_sk = dd_order.d_date_sk                              -- join 2
JOIN date_dim dd_ship                ON cs.cs_ship_date_sk = dd_ship.d_date_sk                               -- join 3
JOIN time_dim tt                     ON cs.cs_sold_time_sk = tt.t_time_sk                                   -- join 4
JOIN call_center cc                  ON cs.cs_call_center_sk = cc.cc_call_center_sk                         -- join 5
JOIN call_center cc2                 ON cs.cs_call_center_sk = cc2.cc_call_center_sk                        -- join 6 (second alias)
JOIN store s                         ON s.s_closed_date_sk = dd_ship.d_date_sk                               -- join 7
JOIN web_sales ws                    ON ws.ws_order_number = cs.cs_order_number                              -- join 8
JOIN (
        SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
    ) ws_sample               ON ws_sample.ws_order_number = ws.ws_order_number                         -- join 9 (sampled alias)
JOIN web_site wsite                  ON ws.ws_web_site_sk = wsite.web_site_sk                               -- join 10
JOIN date_dim dd_ws_open             ON wsite.web_open_date_sk = dd_ws_open.d_date_sk                        -- join 11
JOIN date_dim dd_ws_close            ON wsite.web_close_date_sk = dd_ws_close.d_date_sk                      -- join 12
LEFT JOIN catalog_returns cr        ON cs.cs_order_number = cr.cr_order_number                              -- join 13
LEFT JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk                                      -- join 14
WHERE cs.cs_order_number NOT IN (
        SELECT cr2.cr_order_number FROM catalog_returns cr2
    )
GROUP BY s.s_store_name, dd_order.d_year, s.s_store_sk
ORDER BY total_net_profit DESC
LIMIT 100
