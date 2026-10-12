SELECT 
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    d_start.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns,
    SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_sales,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
    SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_quantity_sales_amount,
    CASE 
        WHEN SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0) > 0 THEN 'POSITIVE' 
        ELSE 'NEGATIVE' 
    END AS profit_indicator
FROM catalog_page cp
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_start.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
GROUP BY 
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    d_start.d_year
ORDER BY net_sales DESC
LIMIT 100
