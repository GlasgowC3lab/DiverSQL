WITH sales_summary AS (
    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        ws_site.web_state,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_profit_after_returns,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        COUNT(*) AS sales_transactions
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d_sales.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND ws.ws_net_profit > 0
    GROUP BY d_sales.d_year,
             d_sales.d_month_seq,
             ws_site.web_state,
             p.p_promo_name
)
SELECT
    ss.d_year,
    ss.d_month_seq,
    ss.web_state,
    ss.p_promo_name,
    ss.total_net_profit,
    ss.total_return_amount,
    ss.net_profit_after_returns,
    ss.total_discount_amount,
    ss.sales_transactions,
    RANK() OVER (PARTITION BY ss.web_state ORDER BY ss.net_profit_after_returns DESC) AS profit_rank
FROM sales_summary ss
WHERE ss.net_profit_after_returns > 10000
ORDER BY ss.d_year, ss.d_month_seq, ss.net_profit_after_returns DESC
LIMIT 100
