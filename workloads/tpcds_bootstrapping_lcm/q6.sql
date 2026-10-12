SELECT 
    cc.cc_state,
    cc.cc_division_name,
    ws.web_market_manager,
    d_closed.d_year,
    d_closed.d_quarter_name,
    CASE 
        WHEN d_closed.d_month_seq BETWEEN 1 AND 6 THEN 'H1' 
        ELSE 'H2' 
    END AS half_year,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT s.s_store_sk) AS distinct_stores,
    COUNT(DISTINCT ws.web_site_sk) AS distinct_web_sites,
    MIN(d_open.d_date) AS earliest_call_center_open,
    MAX(d_ws_close.d_date) AS latest_web_site_close
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_closed.d_date_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_closed.d_date_sk
JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_closed.d_year BETWEEN 2015 AND 2022
  AND (d_closed.d_month_seq % 2) = 0
  AND d_closed.d_quarter_name IS NOT NULL
GROUP BY 
    cc.cc_state,
    cc.cc_division_name,
    ws.web_market_manager,
    d_closed.d_year,
    d_closed.d_quarter_name,
    CASE 
        WHEN d_closed.d_month_seq BETWEEN 1 AND 6 THEN 'H1' 
        ELSE 'H2' 
    END
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
